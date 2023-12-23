#!python3

'''Compare properties and logs with WinMerge.'''

import os, subprocess, winreg
import common


class reg_filter():
    '''Read and restore the current file filter in the registry.'''

    _root_key = winreg.HKEY_CURRENT_USER
    _sub_key = r'Software\Thingamahoochie\WinMerge\Settings'
    _value_name = 'FileFilterCurrent'

    # Changes to True if value is read.
    _value_restore = False

    @classmethod
    def read(cls):
        '''Read the current file filter from the registry.'''

        try:
            with winreg.OpenKey(cls._root_key, cls._sub_key, 0, winreg.KEY_QUERY_VALUE) as key:
                cls._value_data, cls._value_type = winreg.QueryValueEx(key, cls._value_name)
        except FileNotFoundError:
            pass
        else:
            cls._value_restore = True

    @classmethod
    def restore(cls):
        '''Restore the current file filter read to the registry.'''

        if not cls._value_restore:
            return

        try:
            with winreg.OpenKey(cls._root_key, cls._sub_key, 0, winreg.KEY_SET_VALUE) as key:
                winreg.SetValueEx(key, cls._value_name, 0, cls._value_type, cls._value_data)
        except FileNotFoundError:
            print('Unable to restore the file filter registry value.')


def compare_properties(mode):
    '''Compare properties with WinMerge.'''

    # Set the paths.
    exe = os.path.join(os.environ['ProgramFiles'], 'WinMerge', 'WinMergeU.exe')

    if mode == 'embedded_properties':
        src = os.path.join(os.getcwd(), 'scite', 'src', 'Embedded.properties')
        mod = embedded
    elif mode == 'external_properties':
        src = os.path.join(os.getcwd(), 'scite', 'src')
        mod = external
    elif mode == 'embedded_logs':
        src = os.path.join(output, 'changes_before.log')
        mod = os.path.join(output, 'changes_after.log')
    elif mode == 'external_logs':
        src = os.path.join(external, 'changes_before.log')
        mod = os.path.join(external, 'changes_after.log')
    else:
        return

    # Check paths are valid.
    if not os.path.exists(src) or not os.path.exists(mod):
        return

    # Ask to compare.
    reply = input('Compare {}? [n|y]: '.format(mode.replace('_', ' ')))

    if reply.lower() != 'y':
        return

    # Run WinMerge.
    command = [exe, src, mod, '/u']

    if mode == 'external_properties':
        command.extend(['/f', '*.properties'])
        reg_filter.read()

    with subprocess.Popen(command) as p:
        p.wait()

    if mode == 'external_properties':
        reg_filter.restore()


if __name__ == '__main__':

    # Set output path.
    output = common.settings['output']

    # Output paths to compare.
    embedded = os.path.join(output, 'Embedded.properties')
    external = os.path.join(output, 'external_properties')

    # Compare properties and logs.
    if os.path.isfile(embedded):
        compare_properties('embedded_logs')
        compare_properties('embedded_properties')

    if os.path.isdir(external):
        compare_properties('external_logs')
        compare_properties('external_properties')

    print('done')
