#!python3

'''Insert Embedded.properties into Sc1.exe using Resource Hacker.'''

import glob, os, subprocess, urllib.request, zipfile
import common


settings = common.settings

# Keep name of SciTE executable. False=Output as SciTE32.exe and SciTE.exe.
settings['keep_scite_name'] = False

# Test run SciTE. True=Ask to run, False=Do not ask and do not run.
settings['test_run_scite'] = True

# Undefine SciTE environment variables on test run.
settings['undefine_scite_environ_vars'] = True


def get_exe_bitness(file):
    '''Get executable bitness as x86 or x64.'''

    with open(file, 'rb') as r:
        pos = r.read(1024).find(b'PE')
        r.seek(pos + 4, 0)
        char = r.read(1)

    if char == b'd':
        return 'x64'
    elif char == b'L':
        return 'x86'


def download_zip():
    '''Download resource_hacker.zip and extract ResourceHacker.exe.'''

    bin_dir = settings['bin']
    file = os.path.join(bin_dir, 'resource_hacker.zip')
    url = 'http://www.angusj.com/resourcehacker/resource_hacker.zip'

    try:
        urllib.request.urlretrieve(url, file)
    except urllib.error.HTTPError as err_msg:
        print('   ', err_msg)
    else:
        with zipfile.ZipFile(file) as r:
            if 'ResourceHacker.exe' in r.namelist():
                print('extract ResourceHacker.exe')
                r.extract('ResourceHacker.exe', bin_dir)

    reshacker = os.path.join(bin_dir, 'ResourceHacker.exe')

    if os.path.isfile(reshacker):
        return reshacker


if __name__ == '__main__':

    # Set output path.
    output = settings['output']

    # Set download path to access scite executable.
    download = settings['download']

    # Set ResourceHacker path.
    for item in ('ProgramFiles', 'ProgramFiles(x86)'):
        if item in os.environ:
            reshacker = os.path.join(os.environ[item], 'Resource Hacker',
                                     'ResourceHacker.exe')

            if os.path.isfile(reshacker):
                break
    else:
        bin_dir = settings['bin']
        reshacker = os.path.join(bin_dir, 'ResourceHacker.exe')

        if not os.path.isdir(bin_dir):
            os.makedirs(bin_dir)

    if not os.path.isfile(reshacker):
        reply = input('Download resource_hacker.zip? [n|y]: ')

        if reply.lower() == 'y':
            reshacker = download_zip()

        if not reshacker:
            exit('Resource Hacker executable not found.')

    # Set Embedded.properties path.
    for item in (output, os.path.join(os.getcwd(), 'scite', 'src')):

        filepath = os.path.join(item, 'Embedded.properties')

        if os.path.isfile(filepath):
            resfile = filepath
            break
    else:
        exit('Embedded.properties not found.')

    # Set SciTE path.
    scite = []
    version = common.scite_version()

    filepath = os.path.join(os.getcwd(), 'scite', 'bin', 'Sc1.exe')

    if os.path.isfile(filepath):
        scite.append(filepath)

    if not scite:
        if not version:
            exit('Unable to get version to search for SciTE executables')

        for item in ['Sc' + version + '.exe', 'Sc32_' + version + '.exe']:

            filepath = os.path.join(download, item)

            if os.path.isfile(filepath):
                scite.append(filepath)

    if not scite:
        exit('SciTE executable not found.')

    # Run ResourceHacker.
    for infile in scite:

        exe_bitness = get_exe_bitness(infile)

        # Set output file.
        if settings['keep_scite_name']:
            outfile = os.path.join(output, os.path.basename(infile))
        elif infile.endswith('Sc1.exe'):
            if exe_bitness == 'x86':
                outfile = os.path.join(output, 'SciTE32.exe')
            else:
                outfile = os.path.join(output, 'SciTE.exe')
        elif infile.endswith('Sc32_' + version + '.exe'):
            outfile = os.path.join(output, 'SciTE32.exe')
        else:
            outfile = os.path.join(output, 'SciTE.exe')

        if os.path.isfile(outfile):
            os.remove(outfile)

        # Set command.
        command = [reshacker,
                   '-open', infile,
                   '-save', outfile,
                   '-action', 'addoverwrite',
                   '-res', resfile,
                   '-mask', 'PROPERTIES,EMBEDDED,1033',
                   '-log', 'con']

        # Run ResourceHacker.
        with subprocess.Popen(command) as p:
            p.wait()

        if settings['test_run_scite']:
            reply = input('Test run {} now? [n|y]: '
                          .format(os.path.basename(outfile)))

            # Test run SciTE.
            if reply.lower() == 'y':
                if settings['undefine_scite_environ_vars']:
                    env = os.environ.copy()

                    for item in ('SCITE_HOME', 'SCITE_USERHOME'):
                        if item in env:
                            del env[item]
                else:
                    env = None

                with subprocess.Popen([outfile], env=env) as p:
                    p.wait()

    print('done')
