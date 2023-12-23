#!python3

'''Create api and hta files from scintilla.iface file.

The json file created is cached data, collected by use of Face.py.
'''

import html, importlib, json, os, sys
import scintilla.scripts.Face as Face
import common


settings = common.settings

# Make iface.api.
settings['make_api'] = False

# Make iface.hta.
settings['make_hta'] = True


def make_api():
    '''Make an api file.'''

    with open('iface.json') as r:
        dic = json.load(r)

    api = []

    for name, feature in dic.items():
        if feature['FeatureType'] in ('get', 'fun', 'set'):
            calltip = [feature['FeatureType'], name]

            # To match SciTE Lua doc.
            if feature['Param1Name'] == 'length':
                if feature['Param2Type'] == 'string':
                    feature['Param1Type'] = ''
                    feature['Param1Name'] = ''
                elif feature['Param2Type'] == 'stringresult':
                    feature['Param1Type'] = ''
                    feature['Param1Name'] = ''
                    feature['Param2Type'] = ''
                    feature['Param2Name'] = ''

            parameters = '{Param1Type} {Param1Name}, {Param2Type} {Param2Name}' \
                         .format_map(feature).strip()

            if parameters.startswith(',') or parameters.endswith(','):
                parameters = parameters.replace(',', '').strip()

            calltip.append(parameters)

            comment = '\\n '.join(feature['Comment']).rstrip()

            calltip.append(comment)
            calltip.append(feature['ReturnType'])

            api.append(calltip)

    api.sort()

    # Build a combined list of lines sorted for write.
    lines = []

    for item in api:
        if item[0] == 'fun':
            line = '{1}({2}) {3}'.format(*item)
            lines.append('editor:' + line)
            lines.append('output:' + line)
        elif item[0] in ('get', 'set'):
            line = '{1}(-) {0}[{2}]\\n {3}'.format(*item)
            lines.append('editor.' + line)
            lines.append('output.' + line)

    lines.sort()

    with open('iface.api', 'w') as w:
        for line in lines:
            w.write(line + '\n')


def make_hta():
    '''Make an hta file with SciTE functions, getters and setters.'''

    head = ('<!DOCTYPE html>\n'
            '<html>\n\n'
            '<head>\n'
            ' <meta charset="utf-8">\n'
            ' <style>\n'
            '  body {background: #383838}\n'
            '  h1 {color: lightblue; background: #444444; padding: 2px}\n'
            '  pre {border: 1px solid grey; padding: 10px; background-color: #FBFBFB}\n'
            '  table {color: #CCCCCC; background: #333333}\n'
            '  table, th, tr, td {border: #555555 solid 1px; border-collapse: collapse}\n'
            '  th {color: #FFFFFF; background: #000000}\n'
            '  p {color: #CCCCCC}\n'
            '  i {padding: 0px 15px}\n'
            '  .s0 {color: white}\n'
            '  .s1 {color: lightgreen}\n'
            '  .s2 {color: red}\n'
            ' </style>\n'
            '</head>\n\n'
            '<body>\n'
            ' <h1># Scintilla IFace Functions, Getters And Setters</h1>\n\n'
            ' <p><b>Colors:</b> <i>Basics</i> | <i class="s1">Provisional</i> |'
            ' <i class="s2">Deprecated</i> | <i class="s0">No parameters</i></p>\n\n'
            ' <table>\n'
            '  <tr>'
            '<th>FType</th>'
            '<th>Name</th>'
            '<th>Comment</th>'
            '<th>ReturnType</th>'
            '<th>Param1Type</th>'
            '<th>Param1Name</th>'
            '<th>Param2Type</th>'
            '<th>Param2Name</th>'
            '<th>Category</th>'
            '<th>Value</th>'
            '</tr>')

    foot = ' </table>\n\n</body>\n\n</html>'

    with open('iface.json') as r:
        dic = json.load(r)

    with open('iface.hta', 'w') as w:
        w.write(head + '\n')

        for name, data in dic.items():

            # Get the functions, getters and setters.
            if data['FeatureType'] in ('fun', 'get', 'set'):
                data['Comment'] = [html.escape(item) for item in data['Comment']]
                data['Comment'] = ' '.join(data['Comment'])

                if data['ReturnType'] == 'void':
                    data['ReturnType'] = ''

                # Style rows that are Provisional and Deprecated.
                if data['Category'] == 'Basics':
                    data['Category'] = ''
                    style = ''
                elif data['Category'] == 'Provisional':
                    style = ' class="s1"'
                elif data['Category'] == 'Deprecated':
                    style = ' class="s2"'
                else:
                    style = ''

                # Style rows that have no arguments and return value.
                if not style:
                    style = ''

                    for item in ('ReturnType', 'Param1Type', 'Param1Name',
                                 'Param2Type', 'Param2Name'):
                        if data[item] != '':
                            break
                    else:
                        style = ' class="s0"'

                # Write the current row.
                w.write(('  <tr' + style + '>'
                         '<td>{FeatureType}</td>'
                         '<td>' + name + '</td>'
                         '<td>{Comment}</td>'
                         '<td>{ReturnType}</td>'
                         '<td>{Param1Type}</td>'
                         '<td>{Param1Name}</td>'
                         '<td>{Param2Type}</td>'
                         '<td>{Param2Name}</td>'
                         '<td>{Category}</td>'
                         '<td>{Value}</td>'
                         '</tr>\n').format_map(data))

        # End the html with a footer.
        w.write(foot + '\n')


def make_json(scintilla_iface_file, all_features=True):
    '''Make a json file with iface data.'''

    face = Face.Face()
    face.ReadFromFile(scintilla_iface_file)

    if all_features:
        dic = face.features
    else:
        dic = {}

        for name, feature in face.features.items():
            if feature['FeatureType'] in ('fun', 'get', 'set'):
                dic[name] = feature

    with open('iface.json', 'w') as w:
        json.dump(dic, w, indent=4, sort_keys=True)


if __name__ == '__main__':

    # Set output path.
    output = settings['output']

    if not os.path.isdir(output):
        os.makedirs(output)

    # Get initial directory, then change directory to output.
    initial_dir = os.getcwd()
    os.chdir(output)

    print('output:')

    # Make iface.json if not exist.
    if not os.path.isfile('iface.json'):
        print('  iface.json')

        file = os.path.join(initial_dir, 'scintilla',
                            'include', 'Scintilla.iface')

        make_json(file, False)

    # Make iface.api.
    if settings['make_api']:
        make_api()

        if os.path.isfile('iface.api'):
            print('  iface.api')

    # Make iface.hta.
    if settings['make_hta']:
        make_hta()

        if os.path.isfile('iface.hta'):
            print('  iface.hta')

    print('done')
