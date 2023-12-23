#!python3

'''Easy concept to run the scripts by a menu.'''

import glob, os, subprocess, sys


if __name__ == '__main__':

    # List of Python files to run.
    files = ['download_scite.py',
             'download_base_tools.py',
             'download_rluawfx_dll.py',
             'make_scite.py',
             'edit_properties.py',
             'compare_properties.py',
             'insert_embedded.py',
             'make_iface_files.py',
             'make_lua_chm_file.py',
             'make_lua_api_file.py',
             'make_modules_json.py',
             'make_scite_api_files_*.py',
             'make_scite_chm_files.py',
             'make_scite_setup.py',
             'remove_temporary_items.py']

    # Handle arguments passed.
    if len(sys.argv) > 1:
        if sys.argv[1] in ('-h', '/?'):
            print('Menu for Make SciTE Collection.\n\n'
                  'Arguments:\n'
                  '  -h, /?\n'
                  '    Help message.\n'
                  '  -l, /l\n'
                  '    Less menu items.')
            exit()

        if sys.argv[1] in ('/l', '-l'):
            for item in ('make_scite.py',):
                if item in files:
                    files.remove(item)

    # Remove missing files from the list.
    for item in files.copy():
        if '*' in item:
            if not glob.glob(item):
                files.remove(item)
        elif not os.path.isfile(item):
            files.remove(item)

    # Need files to continue.
    if not files:
        exit('No files available')

    # Keep log of previous run entries.
    log = []

    # Loop to show menu and run the entries.
    while 1:
        if log:
            print('\nLog:', ', '.join([str(i) for i in log]))

        print('\nMake SciTE Collection')
        print('-' * 21)
        print(' 0  Quit')

        for index, item in enumerate(files, 1):
            name = os.path.splitext(item)[0]
            name = name.replace('*', '')
            name = name.replace('_', ' ').title()
            name = name.replace('Rluawfx Dll', 'rluawfx.dll')
            name = name.replace('Scite', 'SciTE')
            name = name.strip()
            print('{:2}  {}'.format(index, name))

        replies = input('\nEnter numbers: ').strip().split()

        if not replies:
            exit()

        # Make all numbers and expand number ranges.
        valid_numbers = []

        for reply in replies:
            if '-' not in reply:
                try:
                    number = int(reply)
                except ValueError as err_msg:
                    print('ignoring:', repr(reply), err_msg)
                else:
                    valid_numbers.append(number)
            else:
                items = reply.split('-', 1)

                try:
                    items = range(int(items[0]), int(items[1]) + 1)
                except ValueError as err_msg:
                    print('ignoring:', repr(reply), err_msg)
                else:
                    valid_numbers.extend(items)

        # Ask if OK to continue with numbers remaining.
        if len(valid_numbers) < len(replies):
            print('numbers:', ' '.join(str(number) for number in valid_numbers))

            reply = input('Do you want to continue with these numbers? [n|y]: ')

            if reply.lower() != 'y':
                continue

        # Iterate the replies.
        returncode = 0

        for number in valid_numbers:
            if number == 0:
                exit()

            try:
                file_pattern = files[number - 1]
            except IndexError as err_msg:
                print(err_msg)
            else:
                print()

                for script in glob.iglob(file_pattern):

                    if script.endswith('.py'):
                        command = [sys.executable, script]
                    else:
                        command = [script]

                    print('#', script)

                    with subprocess.Popen(command) as p:
                        p.wait()
                        returncode = p.returncode

                        if returncode:
                            print('Break from loop with details:\n'
                                  '  Number: ' + number + '\n'
                                  '  Script: ' + script + '\n'
                                  '  ReturnCode: ' + returncode)

                            break

                    if '*' in file_pattern:
                        print()

                log.append(number)
            finally:
                if returncode:
                    break
