#!/usr/bin/env python3

'''Read property files and save into 1 json file.'''

import glob, json, os, re
import common


def properties_to_json(src):
    r'''Read properties from src directory.'''

    # Get a list of property files.
    files = []

    if os.path.isfile(os.path.join(src, 'SciTEGlobal.properties')):
        files.append('SciTEGlobal.properties')

    for path in glob.iglob(os.path.join(src, '*.properties')):
        file = os.path.basename(path)

        if file in ('abbrev.properties',
                    'Embedded.properties',
                    'SciTE.properties',
                    'SciTEGlobal.properties'):
            continue

        files.append(file)

    # Prepare the dictionary.
    dic = {'version': '', 'module': {}}

    # Get the editor version.
    version = common.scite_version('.')

    if not version:
        version = input('Enter editor version: ')

    if version:
        dic['version'] = version.replace(',', '.')

    # Create the json file.
    for file in files:
        with open(os.path.join(src, file)) as r:
            module = os.path.splitext(file)[0]
            content = r.read().replace('\t', ' ' * 4).strip('\n') + '\n'
            content = re.sub(r'\n{3,}', r'\n\n', content)
            dic['module'][module] = content

    with open('modules.json', 'w') as w:
        json.dump(dic, w, indent=4)

    return dic


if __name__ == '__main__':

    # Set output path.
    output = common.settings['output']

    if not os.path.isdir(output):
        os.makedirs(output)

    # Get initial directory, then change directory to output.
    initial_dir = os.getcwd()
    os.chdir(output)

    # Read properties and create json file.
    for item in (('modified', os.path.join(output, 'external_properties')),
                 ('default',  os.path.join(initial_dir, 'scite', 'src'))):

        if os.path.isdir(item[1]):
            print('read files from', item[0], 'dir')
            properties_to_json(item[1])
            break

    if os.path.isfile('modules.json'):
        print('output:\n  modules.json')

    print('done')
