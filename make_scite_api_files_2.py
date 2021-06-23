#!/usr/bin/env python3

'''Make scitepane.api file from PaneAPI.html.'''

import os, re, textwrap
import common


if __name__ == '__main__':

    # Set output path and create it if needed.
    output = common.settings['output']

    if not os.path.isdir(output):
        os.makedirs(output)

    # Include additional functions.
    # Items of ? after () are unknown to work in lua.
    # Those with * are considered OK.
    include = [
        'editor.GetCharAt(-)? Arg: [pos]\\n Returns the character byte at the position.',
        'editor.WordStartPosition(-)* Get position of start of word.',
        'editor:CharLeft()* Move caret left one character.',
        'editor:CharRight()* Move caret right one character.',
        'editor:DelLineLeft()? Delete back from the current position to the start of the line.',
        'editor:DelLineRight()? Delete forwards from the current position to the end of the line.',
        'editor:DelWordLeft()? Delete the word to the left of the caret.',
        'editor:DelWordRight()? Delete the word to the right of the caret.',
        'editor:DeleteBack()* Delete the selection or if no selection, the character before the caret.',
        'editor:Home()* Move caret to first position on line.',
        'editor:LineCopy()? Copy the line containing the caret.',
        'editor:LineCut()? Cut the line containing the caret.',
        'editor:LineDelete()? Delete the line containing the caret.',
        'editor:LineDown()* Move caret down one line.',
        'editor:LineEnd()* Move caret to last position on line.',
        'editor:LineUp()* Move caret up one line.',
        'editor:NewLine()* Insert a new line, may use a CRLF, CR or LF depending on EOL mode.',
        'editor:WordLeft()* Move caret left one word.',
        'editor:WordRight()* Move caret right one word.']

    # What can be editor, can also be output.
    for item in include.copy():
        include.append(item.replace('editor', 'output', 1))

    # Read PaneAPI.html.
    file = os.path.join('scite', 'doc', 'PaneAPI.html')

    if not os.path.isfile(file):
        exit('"' + file + '" not found')

    with open(file, encoding='utf-8') as r:
        content = r.read()

    # Remove html head.
    content = re.sub(r'<head.*?>.*?<body.*?>', '', content, flags=re.S|re.I)

    # Remove html tags.
    content = re.sub(r'<!{0,1}.*?>', '', content, flags=re.S)

    # Trim ends of the content.
    content = content.strip()

    # Build the api list.
    api = []

    re_pattern = re.compile(r'\s*(.*?)'
                            r'\s*(editor[:.][a-zA-Z0-9]+)'
                            r'\s*([\(\[].*?[\)\]]){0,1}'
                            r'\s*(.*)')

    for line in content.splitlines():
        if 'editor.' in line or 'editor:' in line:
            matches = re_pattern.findall(line)

            if matches:
                m = [item.strip() for item in matches[0]]

                # Comment.
                comment = []

                if m[3]:
                    m[3] = m[3].replace('\\', '\\\\')
                    m[3] = m[3].replace('-- ', '').strip()
                    m[3] = m[3].replace('read-only', '[read-only]').strip()
                    m[3] = m[3].replace('write-only', '[write-only]').strip()

                    if m[3].startswith('--'):
                        m[3] = m[3][2:].strip()

                    comment = textwrap.wrap(m[3])

                # Return.
                if m[0]:
                    comment.append('Return: ' + m[0])

                # Signature.
                if not m[2]:
                    m[2] = '(-)'
                elif not m[2].count('('):
                    m[2] = '(-)Arguments: ' + m[2] + '\\n'

                # Append.
                if comment:
                    api.append(m[1] + m[2] + '\\n'.join(comment))
                    api.append(m[1].replace('editor', 'output', 1) + m[2] + '\\n'.join(comment))
                else:
                    api.append(m[1] + m[2])
                    api.append(m[1].replace('editor', 'output', 1) + m[2])

    # Sort the list and write the api file.
    if include:
        api.extend(include)

    api.sort()

    # Write to scitepane.api.
    file = os.path.join(output, 'scitepane.api')
    print('output:\n  scitepane.api')

    with open(file, 'w', encoding='utf-8') as w:
        for item in api:
            w.write(item + '\n')

    print('done')
