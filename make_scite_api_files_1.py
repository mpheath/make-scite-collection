#!/usr/bin/env python3

'''Make sciteproperties.api and scitevariables.api files from SciTEDoc.html.'''

import os, re, sys
import common


settings = common.settings

# Set OS specific. True=All properties except for other OSes. False=All.
settings['os_specific'] = True


def get_absent_property_items(content):
    '''Get property items absent of an id attribute.'''

    properties = []

    # Items expected to have a id attribute.
    exclude = ['style.lexer.34', 'style.lexer.35']

    # Brief property doc string.
    doc = {
        'style.lexer.32': 'Default style...',
        'style.lexer.33': 'Line numbers in the margin...',
        'style.lexer.36': 'Control characters...',
        'style.lexer.37': 'Indentation guides...',
        'style.lexer.38': 'Calltips...',
        'command.name.number.filepattern': 'Tools menu text item...',
        'command.number.filepattern': 'Command string...',
        'command.is.filter.number.filepattern': 'Optional...',
        'command.subsystem.number.filepattern': 'Subsytem default is 0...',
        'command.save.before.number.filepattern': '1 auto save 2 no save else ask...',
        'command.input.number.filepattern': 'Windows only. Optional...',
        'command.replace.selection.number.filepattern': 'Optional...',
        'command.quiet.number.filepattern': '1 no echo...',
        'command.mode.number.filepattern': 'Comma-separated list of settings...',
        'command.shortcut.number.filepattern': 'Keyboard shortcut for the command...'}

    for item in doc:
        if doc[item] and not doc[item].startswith('\\n '):
            doc[item] = '\\n ' + doc[item]

    # Get command... property section and style... property section.
    alt = r'command\.name\.<i>number</i>\.<i>filepattern|style\.<i>lexer</i>\.\d'

    matches = re.findall(r'<tr>\s*<td>\s*((?:' + alt + r').*?)\s*</td>',
                         content, re.S|re.I)

    if matches:
        for item in matches:

            # Split into items.
            items = re.split(r'<br />\s*', item, flags=re.S|re.I)

            if items:
                for item in items:

                    # Remove tags.
                    item = re.sub('<.+?>', '', item)

                    # Add to list if not in the exclude list.
                    if item and item not in exclude:
                        properties.append(item + ' (-) [property]' + doc.get(item, ''))

    return properties


if __name__ == '__main__':

    # Set output path.
    output = settings['output']

    if not os.path.isdir(output):
        os.makedirs(output)

    # Read SciTEDoc.html.
    file = os.path.join('scite', 'doc', 'SciTEDoc.html')

    if not os.path.isfile(file):
        exit('"' + file + '" not found')

    with open(file) as r:
        content = r.read()

    # Remove leading classes to ensure matches in the next re pattern.
    if settings['os_specific']:
        classes = ['windowsonly', 'gtkonly', 'osxonly',
                   'windows-osx', 'windows-gtk']

        platforms = [['win32', 'windows'],
                     ['darwin', 'osx'],
                     ['linux', 'gtk']]

        for os_name, class_name in platforms:
            if sys.platform.startswith(os_name):
                print('specific to', class_name)

                for item in classes:
                    if class_name in item:
                        content = re.sub(r'<tr\s+class="' + item + '"',
                                         '<tr', content)
                break
        else:
            print('specific to all')
            content = re.sub(r'<tr\s+class=".+?"', '<tr', content)
    else:
        content = re.sub(r'<tr\s+class=".+?"', '<tr', content)

    # Get the properties and the doc strings.
    scitevariables = []
    sciteproperties = []
    current = {'tag': 'variable', 'list': scitevariables}

    matches = re.findall(r'<tr\s+id=[\'"]property-.+?[\'"].*?>\s*'
                         r'<td>(.+?)</td>\s*<td>(.+?)</td>',
                         content, re.S|re.I)

    if matches:
        for item in matches:

            # Properties can be multiple.
            prop = item[0].split('<br />')

            # Remove html tags.
            prop = [re.sub('<.+?>', '', item).strip() for item in prop]

            # Remove any empty items.
            prop = [item for item in prop if item]

            # Trim the doc string.
            doc = item[1].strip()

            # Replace html breaks with \\n.
            doc = doc.replace('<br />', '\\n')

            # Remove html tags.
            doc = re.sub('<.+?>', '', doc)

            # Replace tabs with spaces.
            doc = re.sub('^\t+', '    ', doc, flags=re.M)

            # Reduce spaces.
            doc = re.sub('^ {2,}', ' ', doc, flags=re.M)

            # Reduce lines.
            doc = re.sub(r'^((?:.+?\n){10}).*', r'\1 ...', doc, flags=re.S)

            # Replace \n with \\n.
            doc = re.sub(r'(?<!\\n)\n', r'\\n', doc)

            # Replace \n with ' '.
            doc = doc.replace('\n', ' ')

            # Change current tag and list once this property is found.
            if prop[0].startswith('position.left'):
                current = {'tag': 'property', 'list': sciteproperties}

            for item in prop:
                current['list'].append('{} (-) [{}]\\n {}'.format(item, current['tag'], doc))

    # Get property items absent of an id attribute.
    items = get_absent_property_items(content)

    if items:
        sciteproperties.extend(items)

    sciteproperties.sort()
    scitevariables.sort()

    print('output:')

    # Write to sciteproperties.api.
    if sciteproperties:
        print('  sciteproperties.api')

        with open(os.path.join(output, 'sciteproperties.api'), 'w') as w:
            for item in sciteproperties:
                w.write(item + '\n')

    # Write to scitevariables.api.
    if scitevariables:
        print('  scitevariables.api')

        with open(os.path.join(output, 'scitevariables.api'), 'w') as w:
            for item in scitevariables:
                w.write(item + '\n')

    print('done')
