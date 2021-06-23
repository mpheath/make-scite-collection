#!/usr/bin/env python3

'''Make hhc, hhk and hhp files to make lexilla.chm, scintilla.chm and scite.chm.'''

import glob, os, re, subprocess
import common


settings = common.settings

# Make only scite.chm. False=Make all chm files.
settings['scite_only'] = False


def make_index(file, outfile):
    '''Make index file for scite.chm.'''

    with open(file) as r:
        content = r.read()

    matches = re.findall(r"(?:id|name)=[\"']property-(.+?)[\"']", content, re.I)

    if not matches:
        return

    matches.sort(key=str.lower)

    with open(outfile, 'w') as w:
        w.write('<!DOCTYPE HTML>\n'
                '<HTML>\n<BODY>\n<UL>\n')

        for item in matches:
            w.write('\t<LI> <OBJECT type="text/sitemap">\n'
                    '\t\t<param name="Name" value="{1}">\n'
                    '\t\t<param name="Local" value="{0}#property-{1}">\n'
                    '\t\t</OBJECT>\n'.format(os.path.basename(file), item))

        w.write('</UL>\n</BODY>\n</HTML>\n')


if __name__ == '__main__':

    # Set Scintilla version.
    scintilla_version = common.scintilla_version('.')

    # Set output path.
    output = settings['output']

    if not os.path.isdir(output):
        os.makedirs(output)

    print('output:')

    # Change directory to these folders.
    for folder in ('lexilla', 'scintilla', 'scite'):

        # Only allow scite.
        if settings['scite_only']:
            if folder != 'scite':
                continue

        # Folders are optional considering lexilla may not exist < SciTE 5.0.
        if not os.path.isdir(folder):
            continue

        # Go to the root folder of the html files.
        os.chdir(folder)
        os.chdir('doc')

        files = glob.glob('*.html')

        # Set initial html file to show in the chm.
        for item in files:
            if item.endswith('Doc.html'):
                default_topic = item
                break
        else:
            default_topic = files[0]

        # Make index file.
        if folder == 'scite' and default_topic.endswith('Doc.html'):
            make_index(default_topic, folder + '.hhk')

            index_key = 'Index file=scite.hhk\n'
        else:
            index_key = ''

        # Set app name.
        app = 'SciTE' if folder == 'scite' else folder.title()

        # Write the project file.
        with open(folder + '.hhp', 'w') as w:
            w.write(('[OPTIONS]\n'
                     'Binary Index=No\n'
                     'Compatibility=1.1 or later\n'
                     'Compiled file={folder}.chm\n'
                     'Contents file={folder}.hhc\n'
                     'Default topic={default_topic}\n'
                     'Display compile progress=No\n'
                     'Enhanced decompilation=Yes\n'
                     'Full-text search=Yes\n'
                     '{index_key}'
                     'Title={app} Help {version}\n'
                     '\n'
                     '[FILES]\n').format(folder=folder,
                                         default_topic=default_topic,
                                         index_key=index_key,
                                         app=app,
                                         version=scintilla_version))

            for item in files:
                w.write(item + '\n')

        # Write the contents file.
        with open(folder + '.hhc', 'w') as w:
            w.write('<!DOCTYPE HTML>\n'
                    '<HTML>\n<BODY>\n'
                    '<OBJECT type="text/site properties">\n'
                    '\t<param name="ImageType" value="Folder">\n'
                    '</OBJECT>\n'
                    '<UL>\n')

            for item in files:
                name = item[:-5]

                if name == 'index':
                    name = 'Index'

                w.write('\t<LI> <OBJECT type="text/sitemap">\n'
                        '\t\t<param name="Name" value="' + name + '">\n'
                        '\t\t<param name="Local" value="' + item + '">\n'
                        '\t\t</OBJECT>\n')

            w.write('</UL>\n</BODY>\n</HTML>')

        # Compile chm files.
        if settings['compiler']:
            outfile = folder + '.chm'
            print(' ', outfile)

            command = [settings['compiler'], folder + '.hhp']

            with subprocess.Popen(command, stdout=subprocess.PIPE) as p:
                stdout = p.communicate()[0]
                stdout = stdout.decode().replace('\r', '')

            if settings['compiler_stdout']:
                print(stdout)

            if os.path.isfile(outfile):
                destination = os.path.join(settings['output'], outfile)

                if os.path.isfile(destination):
                    os.remove(destination)

                os.rename(outfile, destination)

        # Change directory back to the main root folder.
        os.chdir('..')
        os.chdir('..')

    print('done')
