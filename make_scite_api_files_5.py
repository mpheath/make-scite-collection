#!/usr/bin/env python3

'''Make scitestyler.api file from ScriptLexer.html.'''

import os, re
import common


if __name__ == '__main__':

    # Set output path.
    output = common.settings['output']

    if not os.path.isdir(output):
        os.makedirs(output)

    # Read ScriptLexer.html.
    file = os.path.join('scite', 'doc', 'ScriptLexer.html')

    if not os.path.isfile(file):
        exit('"' + file + '" not found')

    with open(file, encoding='utf-8') as r:
        content = r.read()
        content = content.replace('\u2192', ':')

    # Get commands, return values and comments.
    matches = re.findall(r'<table.+?>.*?</table>', content, re.I|re.S)

    if matches:
        matches = re.findall(r'<tr><td>(.*?)(?: : (\w+)){0,1}</td>\s*<td>(.*?)</td></tr>', matches[-1], re.I|re.S)

        stylers = []

        for item in matches:
            signature, retval, comment = item

            comment = re.sub('\r?\n|\t', ' ', comment)
            comment = re.sub(' {2,}', ' ', comment)

            if ')' in signature:
                if retval:
                    pattern = '{0} {2}\\n Return: {1}'
                else:
                    pattern = '{0} {2}'
            else:
                pattern = '{0} (-) [{1}]\\n {2}'

            pattern = 'styler:' + pattern

            stylers.append(pattern.format(signature, retval, comment))

        # Write to scitemenucommands.api.
        if stylers:
            stylers.sort()

            print('output:\n  scitestyler.api')

            with open(os.path.join(output, 'scitestyler.api'), 'w', encoding='utf-8') as w:
                for item in stylers:
                    w.write(item + '\n')

    print('done')