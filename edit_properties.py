#!/usr/bin/env python3

'''Edit the embedded or external property files.

Add font.override, change literal colour styles to variable and do minor fixes.
May read patch.md for text find and replace.
'''

import hashlib, os, re
import common


class EditProperties():
    '''Edit properties files and save to output.'''

    def __init__(self, use_embedded=True, font_override=True,
                       mode=1, output=common.settings['output']):
        '''Setup using parameter values and copy the list named _modified.

        Parameters:
          use_embedded:
            True=Use Embedded.properties.
            False=Use external properties files.
          font_override:
            True=Add property font.override=$(font.monospace)
            False=Do not add the property.
          mode:
            0=Do not use patch.md.
            1=Use patch.md.
          output:
            Path to the root of the output folder.
            Default is common.settings['output']
        '''

        self.font_override = font_override
        self.mode = mode
        self.modified = _modified.copy()
        self.output = output
        self.use_embedded = use_embedded

    def make(self):
        '''Read properties files and write the modified files.'''

        def _move_global_header(content, modified):
            '''Move header from content to the beginning of the modified list.'''

            header = (
                '# Global initialisation file for SciTE\n'
                '# For Linux, place in $prefix/share/scite\n'
                '# For Windows, place in same directory as SciTE.EXE (or Sc1.EXE)\n'
                '# Documentation at http://www.scintilla.org/SciTEDoc.html\n'
                '\n'
                '# Globals\n')

            before = len(content)
            content = content.replace(header, '')

            if len(content) != before:
                new_header = header.splitlines()
                modified = new_header + modified

            return content, modified

        # Set local names.
        font_override = self.font_override
        mode = self.mode
        modified = self.modified
        output = self.output
        use_embedded = self.use_embedded

        # Set source path to properties files.
        src = os.path.join('scite', 'src')

        # Set output path and create it if needed.
        if not use_embedded:
            output = os.path.join(output, 'external_properties')

        if not os.path.isdir(output):
            os.makedirs(output)

        # Use font.override.
        if font_override:
            modified.append('font.override=$(font.monospace)')

        # Record line changes of before and after.
        changelog = []

        for item in modified:
            changelog.append(['', item])

        # Get patches.
        patches = get_patches() if mode == 1 else {}

        # Record patch statistics for a final report.
        if patches:
            patch_stats = {'failed': 0, 'passed': 0}
        else:
            patch_stats = {}

        # Compile regular expressions.
        re_hex_upper = re.compile('(fore|back):#([0-9a-f]{6})')
        re_hex_len = re.compile('(#[a-zA-Z0-9]{6})[a-zA-Z0-9]{2}')

        # Get a list of properties files.
        if use_embedded:
            files = ['Embedded.properties']
        else:
            files = get_properties_filenames(src)

        # The initial module name that get updated with the next module name.
        module = 'SciTEGlobal'

        # Once modules header printed, this value will be cleared.
        modules_header = 'modules:'

        for file in files:

            # Get module name.
            if file in ('Embedded.properties', 'SciTEGlobal.properties'):
                module = 'SciTEGlobal'
            else:
                module = os.path.splitext(file)[0]

            # Read the external properties source file.
            with open(os.path.join(src, file)) as r:
                content = r.read()

            # Move global header to top of the modified list.
            if file == 'SciTEGlobal.properties':
                content, modified = _move_global_header(content, modified)

            # Apply embedded file patches.
            if mode == 1:
                if file == 'Embedded.properties':
                    print('patches:')

                    for key, items in patches.items():
                        for item in items:
                            before_hash = hashlib.md5(content.encode()).hexdigest()
                            content = content.replace(item[1], item[2], 1)
                            after_hash = hashlib.md5(content.encode()).hexdigest()

                            if before_hash == after_hash:
                                patch_stats['failed'] += 1
                                status = 'n'
                            else:
                                patch_stats['passed'] += 1
                                status = 'y'

                            print('  {} {}: {}'.format(status, key, item[0]))

            # Print module name.
            if modules_header:
                print(modules_header)
                modules_header = ''

            print(' ', module)

            # Apply external file patches.
            if mode == 1:
                if file != 'Embedded.properties':
                    if module in patches:
                        for item in patches[module]:
                            before_hash = hashlib.md5(content.encode()).hexdigest()
                            content = content.replace(item[1], item[2], 1)
                            after_hash = hashlib.md5(content.encode()).hexdigest()

                            if before_hash == after_hash:
                                patch_stats['failed'] += 1
                                status = 'n'
                            else:
                                patch_stats['passed'] += 1
                                status = 'y'

                            print('    {} {}'.format(status, item[0]))

            # Reset modified list if not global.
            if module != 'SciTEGlobal':
                modified = []

            # Read file content split into lines.
            for line in content.splitlines():

                # Get module name if embedded.
                if file == 'Embedded.properties':
                    if line.startswith('module '):
                        matches = line.strip().split()

                        if len(matches) == 2:
                            module = matches[1]
                            print(' ', module)

                # Record before.
                before = line

                # Update these font props in the global module.
                if module == 'SciTEGlobal':
                    if font_override and line.lstrip().startswith('font.'):
                        if line.lstrip().startswith('font.quality='):
                            pass
                        elif line.lstrip().startswith('font.monospace='):
                            line = re.sub('size:(?:8.9|9)$', 'size:10', line)
                        else:
                            line = line.rstrip() + ',$(font.override)'

                # Fix ecl module as colours are 6 digits, not 8.
                if module == 'ecl':
                    if line.startswith('style.'):
                        line = re_hex_len.sub(r'\1', line)

                # Remove registry module malformed comment line.
                elif module == 'registry':
                    if line == '[Styles]':
                        continue

                # Update props in any module from update dict.
                if module in _update:
                    for name, value in _update[module]:
                        if line.startswith(name + '='):
                            if line.endswith('\\'):
                                print('Cannot update', name, 'with value', value,
                                      'as the line has a continuation character.')
                            else:
                                if value is None:
                                    line = ''
                                else:
                                    line = name + '=' + value

                # Replace in style line.
                if line.startswith('style.'):
                    line = re_hex_upper.sub(lambda m:
                                            m.group(1) + ':#' + m.group(2).upper(),
                                            line)

                    if '.0=' in line:
                        for items in (('fore:#000000', '$(colour.default)'),
                                      ('fore:#7F7F7F', '$(colour.whitespace)'),
                                      ('fore:#808080', '$(colour.whitespace)')):

                            if items[0] in line:
                                line = line.replace(*items)
                                break

                    for items in _styles:
                        if items[0] in line:
                            line = line.replace(*items)

                # Update changelog list.
                if line != before:
                    changelog.append([before, line])

                # Update modified list.
                modified.append(line)

            # Write the modified properties file.
            with open(os.path.join(output, file), 'w') as w:
                for line in modified:
                    w.write(line + '\n')

        # Write log files.
        with open(os.path.join(output, 'changes_before.log'), 'w') as w1, \
             open(os.path.join(output, 'changes_after.log'), 'w') as w2:

            for before, after in changelog:
                w1.write(before + '\n')
                w2.write(after + '\n')

        # Print final report.
        if patch_stats:
            print(('patches:\n'
                   '  passed: {passed}\n'
                   '  failed: {failed}').format_map(patch_stats))

        print('changelog:\n'
              '  items:', len(changelog))


def get_patches():
    '''Get patches and return a dictionary.'''

    if not os.path.exists('patch.md'):
        print('No patches as patch.md not found.')
        return None

    # Read the patch.md file.
    with open('patch.md') as r:
        content = r.read()

        # Remove documentation at beginning of content.
        content = re.sub('^# .+?\n---\n', '', content, 1, re.S)

    dic = {}

    # Get the re matches from patch.md content.
    matches = re.finditer(r'\n#### *(.+?) *: *(.+?)\n+'
                          r'.*?'
                          r'```\n(.+?)```\n+'
                          r'```\n(.+?)```\n', content, re.S)

    # Iterate the matches and add into a dictionary.
    for item in matches:
        module, comment, find, repl = item.groups()

        if module.startswith(('-', '~')):
            continue

        if module not in dic:
            dic[module] = [[comment, find, repl]]
        else:
            dic[module].append([comment, find, repl])

    return dic


def get_properties_filenames(path):
    '''Get external properties filenames and return a list.'''

    # Files to ignore.
    ignore_files = ['abbrev.properties',
                    'Embedded.properties',
                    'SciTE.properties',
                    'SciTEGlobal.properties']

    # Ensure SciTEGlobal is 1st item.
    capture_files = ['SciTEGlobal.properties']

    # Build the file list.
    with os.scandir(path) as r:
        for item in r:
            if item.name.endswith('.properties') and item.is_file():
                if item.name not in ignore_files:
                    capture_files.append(item.name)

    # Only 1 item implies none found.
    if len(capture_files) == 1:
        return []

    return capture_files


# Style variable references.
# Colour naming based on HTML 16 colour range.
_styles = [
    # Replace similar colours before variable replacements.
    ['fore:#000080', 'fore:#00007F'], # keyword
    ['fore:#008000', 'fore:#007F00'], # code.comment.line
    ['fore:#008080', 'fore:#007F7F'], # number
    ['fore:#800000', 'fore:#7F0000'], # maroon
    ['fore:#800080', 'fore:#7F007F'], # string
    ['fore:#808000', 'fore:#7F7F00'], # preproc
    ['fore:#808080', 'fore:#7F7F7F'], # grey
    # Replace fixed style values with standard variables.
    ['back:#E0EEFF', '$(colour.embedded.comment)'],
    ['back:#F0F0FF', '$(colour.embedded.js)'],
    ['back:#FF0000', '$(colour.notused)'],
    ['fore:#000000', '$(colour.operator)'],
    ['fore:#00007F', '$(colour.keyword)'],
    ['fore:#0000FF,back:#D0F0D0', '$(colour.text.comment)'],
    ['fore:#007F00', '$(colour.code.comment.line)'],
    ['fore:#007F7F', '$(colour.number)'],
    ['fore:#3F703F', '$(colour.code.comment.doc)'],
    ['fore:#7F007F', '$(colour.string)'],
    ['fore:#7F7F00', '$(colour.preproc)'],
    ['fore:#A0C0A0', '$(colour.code.comment.nested)'],
    ['fore:#FFFF00,back:#FF0000', '$(colour.error)'],
    ['fore:#B06000', '$(colour.other.operator)'],
    # Replace fixed style values with non-standard variables.
    ['fore:#0000FF', '$(colour.blue)'],
    ['fore:#00FF00', '$(colour.lime)'],
    ['fore:#00FFFF', '$(colour.aqua)'],
    ['fore:#7F0000', '$(colour.maroon)'],
    ['fore:#7F7F7F', '$(colour.grey)'],
    ['fore:#C0C0C0', '$(colour.silver)'],
    ['fore:#FF0000', '$(colour.red)'],
    ['fore:#FF00FF', '$(colour.fuchsia)'],
    ['fore:#FFFF00', '$(colour.yellow)'],
    ['fore:#FFFFFF', '$(colour.white)']]


# Update property values.
# Use patch.md for multiline values.
_update = {
    'au3': [
        # Bolden keyword and function.
        ['style.au3.4', '$(colour.keyword),bold'],
        ['style.au3.5', '$(colour.keyword),bold'],
        # Remove back from string.
        ['style.au3.7', '$(colour.string)'],
        # Remove back from sendkey string.
        ['style.au3.10', '$(colour.string),bold'],
        # Remove back from pre-processor.
        ['style.au3.11', '$(colour.preproc)'],
        # Remove back from special and change fore to red.
        ['style.au3.12', 'fore:#FF0000'],
    ],
    'caml': [
        # Fix colour value '#a0000' length.
        ['style.caml.5', 'fore:#A00000,bold'],
    ],
    'cobol': [
        # Fix incorrect variable name.
        ['style.COBOL.3', '$(colour.code.comment.doc),$(font.code.comment.doc)'],
    ],
    'html': [
        # Fixes for php. Styles to be set colours like other languages.
        # Change colour.code.comment.line to colour.maroon.
        ['style.hypertext.104', '$(colour.maroon),italics,$(colour.hypertext.server.php.back)'],
        # Change fore:#000033 to colour.keyword.
        ['style.hypertext.118', '$(colour.keyword),$(colour.hypertext.server.php.back),eolfilled'],
        # Change colour.code.comment.line to colour.string.
        ['style.hypertext.119', '$(colour.string),$(colour.hypertext.server.php.back)'],
        # Change fore:#009F00 to colour.string.
        ['style.hypertext.120', '$(colour.string),$(colour.hypertext.server.php.back)'],
        # Change colour.string to colour.keyword.
        ['style.hypertext.121', '$(colour.keyword),italics,$(colour.hypertext.server.php.back)'],
        # Change fore:#CC9900 to colour.number.
        ['style.hypertext.122', '$(colour.number),$(colour.hypertext.server.php.back)'],
        # Change colour.keyword to colour.maroon.
        ['style.hypertext.123', '$(colour.maroon),italics,$(colour.hypertext.server.php.back)'],
        # Change fore:#999999 to colour.code.comment.line.
        ['style.hypertext.124', '$(colour.code.comment.line),$(font.comment),$(colour.hypertext.server.php.back),eolfilled'],
        # Change fore:#666666 to colour.code.comment.line.
        ['style.hypertext.125', '$(colour.code.comment.line),italics,$(font.comment),$(colour.hypertext.server.php.back)'],
        # Change colour.code.comment.line to colour.maroon.
        ['style.hypertext.126', '$(colour.maroon),italics,$(colour.hypertext.server.php.back)'],
    ],
    'inno': [
        # Set default style to a variable.
        ['style.inno.0', '$(colour.default)'],
        # Change colour.string to colour.keyword.
        ['style.inno.3', '$(colour.keyword)'],
        # Remove back and bolden section head.
        ['style.inno.4', 'bold'],
    ],
    'json': [
        # Fix missing # character in fore colour.
        ['style.json.0', 'fore:#FFFFFF'],
    ],
    'lua': [
        # Bolden keyword.
        ['style.lua.5', '$(colour.keyword),bold'],
        # Change "$(colour.char)" to "$(colour.string)".
        ['style.lua.7', '$(colour.string)'],
        # Change other keywords (bozo test colors...) remove back colours.
        ['style.lua.13', '$(style.lua.5)'],
        ['style.lua.14', '$(style.lua.5)'],
        ['style.lua.15', '$(style.lua.5)'],
        ['style.lua.16', '$(style.lua.5)'],
        ['style.lua.17', '$(style.lua.5)'],
        ['style.lua.18', '$(style.lua.5)'],
        ['style.lua.19', '$(style.lua.5)'],
    ],
    'markdown': [
        # More colourful styles.
        ['style.markdown.2', '$(colour.string),bold'],
        ['style.markdown.3', '$(colour.string),bold'],
        ['style.markdown.4', '$(colour.string),italics'],
        ['style.markdown.5', '$(colour.string),italics'],
        ['style.markdown.6', 'fore:#FF7766,bold'],
        ['style.markdown.7', 'fore:#FF9966,bold'],
        ['style.markdown.8', 'fore:#FFBB66,bold'],
        ['style.markdown.9', 'fore:#FFBB66,bold'],
        ['style.markdown.10', 'fore:#FFDD66,bold'],
        ['style.markdown.11', 'fore:#FFDD66,bold'],
        ['style.markdown.12', 'fore:#000000'],
        ['style.markdown.13', 'fore:#00BB33,bold,back:#F6FFF6'],
        ['style.markdown.14', 'fore:#00BB33,bold'],
        ['style.markdown.15', 'fore:#00BB33,bold,back:#F6FFF6'],
        ['style.markdown.16', 'fore:#777777'],
        ['style.markdown.17', 'fore:#00BB33,bold'],
        ['style.markdown.18', 'fore:#2E39B3,back:#F9F9FF'],
        ['style.markdown.19', 'back:#F5F5F5,$(colour.keyword),$(font.monospace)'],
        ['style.markdown.20', 'back:#F5F5F5,$(colour.keyword),$(font.monospace),eolfilled'],
        ['style.markdown.21', 'back:#F5F5F5,$(colour.keyword),$(font.monospace),eolfilled'],
    ],
    'others': [
        # Change dark background on batch labels to lighter colour.
        ['style.batch.3', '$(colour.embedded.js),bold,eolfilled'],
        # Change text colour to comment colour and not to be bold.
        ['style.batch.8', '$(style.batch.3),$(colour.code.comment.line),notbold'],
    ],
    'powerpro': [
        # Fix '#fore:$(font.base)' value.
        ['style.powerpro.0', 'fore:#000000,$(font.base)'],
        # Fix missing the fore keyname.
        ['style.powerpro.12', 'fore:#0000FF'],
    ],
    'powershell': [
        # Change fixed styles to colours similar to the others.
        ['style.powershell.2', '$(colour.string)'],
        ['style.powershell.3', '$(colour.string)'],
        ['style.powershell.4', '$(colour.number)'],
        ['style.powershell.5', '$(colour.maroon)'],
        ['style.powershell.9', '$(colour.keyword)'],
    ],
    'python': [
        # Add fore style to bold only operators.
        ['style.python.10', '$(colour.operator),bold'],
        # Braces. Keep empty else does not inherit global.
        ['style.python.34', ''],
        ['style.python.35', ''],
    ],
    'specman': [
        # Fix 'fore:red' value.
        ['style.specman.3', 'fore:#FF0000'],
    ],
    'tacl':[
        # Fix incorrect variable name.
        ['style.TACL.3', '$(colour.code.comment.doc),$(font.code.comment.doc)'],
    ],
    'tal': [
        # Fix incorrect variable name.
        ['style.TAL.3', '$(colour.code.comment.doc),$(font.code.comment.doc)'],
    ],
    'vb': [
        # Bolden keyword.
        ['style.vb.3', '$(colour.keyword),bold'],
    ]}


# Each modified line is appended to this list.
# These preset lines are for Embedded and SciTEGlobal.
_modified = [
    'colour.default=fore:#000000',
    'colour.whitespace=fore:#808080',
    'colour.blue=fore:#0000FF',
    'colour.lime=fore:#00FF00',
    'colour.aqua=fore:#00FFFF',
    'colour.maroon=fore:#7F0000',
    'colour.grey=fore:#7F7F7F',
    'colour.silver=fore:#C0C0C0',
    'colour.red=fore:#FF0000',
    'colour.fuchsia=fore:#FF00FF',
    'colour.yellow=fore:#FFFF00',
    'colour.white=fore:#FFFFFF']


if __name__ == '__main__':

    # Changes to '\n' to separate 2nd output from the 1st output.
    newline = ''

    # Ask to edit properties and do so if allowed.
    for items in (('Embedded.properties', True),
                  ('External Properties', False)):

        reply = input('{}Edit {}? [n|y]: '.format(newline, items[0]))

        if reply.lower() == 'y':
            newline = '\n'
            instance = EditProperties(items[1])
            instance.make()

    print('done')
