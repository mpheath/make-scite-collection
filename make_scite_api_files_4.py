#!python3

'''Make scitemenucommands.api file from CommandValues.html.'''

import os, re
import common


if __name__ == '__main__':

    # Set output path.
    output = common.settings['output']

    if not os.path.isdir(output):
        os.makedirs(output)

    # Read CommandValues.html.
    file = os.path.join('scite', 'doc', 'CommandValues.html')

    if not os.path.isfile(file):
        exit('"' + file + '" not found')

    with open(file, encoding='utf-8') as r:
        content = r.read()

    # Get commands with comments.
    matches = re.findall(r'<table>*?>(.*?)</table>', content, re.I|re.S)

    if matches:
        matches = re.findall(r'<td>(.*?)</td><td>(.*?)</td>', matches[0], re.I|re.S)

        # Write to scitemenucommands.api.
        if matches:
            matches.sort()

            print('output:\n  scitemenucommands.api')

            with open(os.path.join(output, 'scitemenucommands.api'), 'w', encoding='utf-8') as w:
                for item in matches:
                    w.write('{} (-) {}\n'.format(item[0], item[1]))

    print('done')
