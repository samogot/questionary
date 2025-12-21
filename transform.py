import argparse
import contextlib
import csv
import linecache
import os
import re
import shutil
import sys
import textwrap
import traceback

import hjson
import saxonche
from lxml import etree

has_errors = False


def parse_args():
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--input-file', nargs='?')
    group.add_argument('--input-dir')
    parser.add_argument('--output-dir', required=True)
    parser.add_argument('--scheme-file', default='questionary2.xsd')
    parser.add_argument('--transform-xslt', default='transform.xsl')
    parser.add_argument('--extract-xslt', default='extract.xsl')
    parser.add_argument('--bulletin-xslt', default='bulletin.xsl')
    parser.add_argument(
        '--base-url',
        default='https://questionary.iris-psy.org.ua/android_asset/run.html')
    parser.add_argument(
        '--bulletin-url',
        default='https://questionary.iris-psy.org.ua/bulletin.php?ind_type=all&bulletin_id=')
    parser.add_argument(
        '--exit-url',
        default='https://questionary.iris-psy.org.ua/android_asset')
    parser.add_argument('--override', action=argparse.BooleanOptionalAction,
                        default=True)
    parser.add_argument('--remove-input', action=argparse.BooleanOptionalAction,
                        default=False)
    parser.add_argument('--ignore-schema', action=argparse.BooleanOptionalAction,
                        default=False)
    parser.add_argument('--block-on-error', action=argparse.BooleanOptionalAction,
                        default=True)
    parser.add_argument('--bulletin-all-combinations', action=argparse.BooleanOptionalAction,
                        default=False)
    return parser.parse_args()


def format_snippet_line(file, line, pad):
    return '{0} | {1}\n'.format(str(line).rjust(pad), linecache.getline(file, line).rstrip())


def print_error_log(error_log):
    for log in error_log:
        message = log.message.replace('{https://questionary.iris-psy.org.ua/schema2}', '')
        error = (f'{log.filename}:{log.line:d}:{log.column:d} '
                 f'{log.level_name}:{log.domain_name}:{log.type_name}: {message}\n')

        num_len = len(str(log.line + 1))
        if log.line > 1:
            error += format_snippet_line(log.filename, log.line - 1, num_len)
        error += format_snippet_line(log.filename, log.line, num_len)
        error += ' ' * num_len + ' . ' + ' ' * (log.column - 1) + '^\n'
        error += format_snippet_line(log.filename, log.line + 1, num_len)
        print(error, file=sys.stderr)


def validate(src_path: str, schema_path: str, ignore_schema: bool):
    global has_errors
    if not os.path.exists(src_path):
        print(f'File {src_path!r} not found', file=sys.stderr)
        has_errors = True
        return False
    schema = etree.XMLSchema(file=schema_path)
    parser = etree.XMLParser()
    try:
        xmldoc = etree.parse(src_path, parser)
    except etree.XMLSyntaxError as e:
        if e.error_log:
            print_error_log(e.error_log)
            has_errors = True
            return False
        # noinspection PyProtectedMember
        error_code = etree.ErrorTypes._getName(e.code, f'unknown_{e.code}')
        print(f'{str(e.filename)}:{e.lineno}:{e.offset} {error_code}: {e.msg}',
              file=sys.stderr)
        has_errors = True
        return False
    if parser.error_log:
        print_error_log(parser.error_log)
        has_errors = True
        return False
    if not schema.validate(xmldoc):
        print_error_log(schema.error_log)
        has_errors = True
        return ignore_schema
    return True


def extract_header(src_path, dst_path, xslt_path, encoding='cp1251'):
    try:
        attrs = ['id', 'text', 'sticky-text', 'question-text', 'subquestion-text',
                 'answer-text', 'input-text']
        with saxonche.PySaxonProcessor(license=False) as proc:
            xsltproc = proc.new_xslt30_processor()
            header_xml = xsltproc.transform_to_value(source_file=src_path,
                                                     stylesheet_file=xslt_path)
            with open(dst_path, 'w', encoding=encoding) as f:
                values = set()
                for field in header_xml[0].children:
                    for v in field.children:
                        values.add(int(v.get_attribute_value('num')))
                values.discard(0)
                csv_writer = csv.DictWriter(f, fieldnames=[*attrs, 'values', *sorted(values)],
                                            dialect='unix', delimiter=';')
                csv_writer.writeheader()
                for field in header_xml[0].children:
                    row = {a: field.get_attribute_value(a) for a in attrs}
                    for v in field.children:
                        row[int(v.get_attribute_value('num'))] = v.get_attribute_value('text')
                    row.pop(0, None)
                    csv_writer.writerow(row)
    except UnicodeEncodeError:
        if encoding != 'utf-8':
            extract_header(src_path, dst_path, xslt_path, 'utf-8')
        else:
            raise


def create_sps_labels(src_path, dst_path, xslt_path):
    with saxonche.PySaxonProcessor(license=False) as proc:
        xsltproc = proc.new_xslt30_processor()
        header_xml = xsltproc.transform_to_value(source_file=src_path,
                                                 stylesheet_file=xslt_path)
        with open(dst_path, 'w', encoding='utf-8') as f:
            for field in header_xml[0].children:
                quest_key = field.get_attribute_value('id')
                label = field.get_attribute_value('text').replace("'", "''")
                values = {v.get_attribute_value('num'): v.get_attribute_value('text').replace("'", "''")
                          for v in field.children}
                values = '\n'.join(f"{k} '{v}'" for k, v in values.items())
                f.write(f"VARIABLE LABELS\n{quest_key} '{label}'.\n")
                if values:
                    f.write(f"VALUE LABELS\n{quest_key}\n{values}.\n\n")
            f.write('EXECUTE.')


MIN_COMMON_LEN = 10


def group_similar_questions(questions):
    """
    Detects groups of similar questions based on type, answers, and common text prefixes/suffixes.

    Args:
    questions: A list of question dictionaries.

    Returns:
    A list of dictionaries, each representing a group of similar questions.
    """

    # First pass: group by type, answers/from-to
    groups = []
    current_group = None
    for question in questions:
        if '_sub' in question['id']:
            continue
        # Extract question number from id
        match = re.match(r"quest(\d+)", question['id'])
        question_number = int(match.group(1))

        if current_group is None:
            current_group = {
                'start': question_number,
                'type': question['type'],
                'answs': question.get('answs'),
                'from': question.get('from'),
                'to': question.get('to'),
                'questions': [{'id': question['id'], 'text': question['text']}]
            }
        else:
            is_similar = (
                    question['type'] == current_group['type'] and
                    question.get('answs') == current_group['answs'] and
                    question.get('from') == current_group['from'] and
                    question.get('to') == current_group['to']
            )
            if is_similar:
                current_group['questions'].append({'id': question['id'], 'text': question['text']})
            else:
                groups.append(current_group)
                current_group = {
                    'start': question_number,
                    'type': question['type'],
                    'answs': question.get('answs'),
                    'from': question.get('from'),
                    'to': question.get('to'),
                    'questions': [{'id': question['id'], 'text': question['text']}]
                }
    if current_group:
        groups.append(current_group)

    # Second pass: extract unique parts and split by prefix/suffix
    final_groups = []
    for group in groups:
        # Initialize prefix and suffix with the first question's text
        prefix = group['questions'][0]['text']
        suffix = group['questions'][0]['text']

        # Temporary list to hold questions for the current subgroup
        subgroup = []

        for question in group['questions']:
            new_prefix = _common_prefix(question['text'], prefix)
            new_suffix = _common_suffix(question['text'], suffix)

            # Check if prefix/suffix dropped below threshold
            if subgroup and len(new_prefix) <= MIN_COMMON_LEN and len(new_suffix) <= MIN_COMMON_LEN:
                # Finalize the current subgroup and start a new one
                _finalize_group(group, prefix, suffix, subgroup, final_groups)
                subgroup = []
                prefix = question['text']  # Reset prefix/suffix for the new subgroup
                suffix = question['text']
            else:
                prefix = new_prefix
                suffix = new_suffix
            subgroup.append(question)

        # Finalize the last subgroup
        _finalize_group(group, prefix, suffix, subgroup, final_groups)

    return final_groups


def _finalize_group(group, prefix, suffix, subgroup, final_groups):
    """
    Finalizes a group by stripping prefix/suffix and adding it to the final list.
    """
    if not subgroup:
        return
    for q in subgroup:
        q['full_text'] = q['text']
    if len(subgroup) > 1:
        for q in subgroup:
            if prefix:
                q['text'] = q['text'][len(prefix):]  # Strip prefix
            if suffix:
                q['text'] = q['text'][:-len(suffix)]  # Strip suffix
            q['text'] = q['text'].strip()
    final_groups.append({
        'start': group['start'],
        'type': group['type'],
        'prefix': prefix.strip(),
        'suffix': suffix.strip(),
        'answs': group.get('answs'),
        'from': group.get('from'),
        'to': group.get('to'),
        'questions': subgroup
    })
    group['start'] += len(subgroup)


def _common_prefix(s1, s2):
    """
    Returns the longest common prefix of two strings, splitting only at spaces.
    """
    s1_words = s1.split()
    s2_words = s2.split()
    i = 0
    while i < len(s1_words) and i < len(s2_words) and s1_words[i] == s2_words[i]:
        i += 1
    return ' '.join(s1_words[:i])


def _common_suffix(s1, s2):
    """
    Returns the longest common suffix of two strings, splitting only at spaces.
    """
    s1_words = s1.split()[::-1]
    s2_words = s2.split()[::-1]
    i = 0
    while i < len(s1_words) and i < len(s2_words) and s1_words[i] == s2_words[i]:
        i += 1
    return ' '.join(s1_words[:i][::-1])


def create_bulletin_stub(src_path, dst_path, xslt_path, base_name, all_ones=False):
    attrs = ['id', 'type', 'text', 'from', 'to']
    answ_attrs = ['id', 'text']
    with saxonche.PySaxonProcessor(license=False) as proc:
        xsltproc = proc.new_xslt30_processor()
        bul_xml = xsltproc.transform_to_value(source_file=src_path,
                                              stylesheet_file=xslt_path)
        quests = []
        for field in bul_xml[0].children:
            e = {a: field.get_attribute_value(a) for a in attrs}
            quests.append(e)
            answs = e['answs'] = []
            for answ in field.children:
                answs.append({a: answ.get_attribute_value(a) for a in answ_attrs})
        json = []
        groups = group_similar_questions(quests)
        for g in groups:
            if g['type'] in ('scale', 'number'):
                b = {
                    'type': 'avg',
                    'num': g['start'],
                    'count': len(g['questions']),
                }
                m = re.search(r'_input(\d+)', g['questions'][0]['id'])
                if m:
                    b['input'] = int(m.group(1))
                b.update({
                    'text': g['prefix'],
                    'vars': ['', *(q['text'] for q in g['questions'])]
                })
                json.append(b)
                if g['type'] == 'scale' and all_ones:
                    for i, q in enumerate(g['questions']):
                        json.append({
                            'type': 'one',
                            'num': g['start'] + i,
                            'text': q['full_text'],
                            'vars': ['', *range(int(g['from']), int(g['to']) + 1)]
                        })
            elif g['type'] == 'multiselect':
                json.append({
                    'type': 'multi',
                    'num': g['start'],
                    'count': len(g['answs']),
                    'text': g['prefix'],
                    'vars': ['', *(a['text'] for a in g['answs'])]
                })
            elif g['type'] == 'treeselect':
                for i, q in enumerate(g['questions']):
                    json.append({
                        'type': 'one',
                        'num': g['start'] + i,
                        'text': q['full_text'],
                        'vars': {a['id']: a['text'] for a in g['answs']}
                    })
            else:
                if len(g['questions']) > 1:
                    json.append({
                        'type': 'pct',
                        'num': g['start'],
                        'count': len(g['questions']),
                        '_todo_pick_values': {(a.get('id') or i + 1): a['text'] for i, a in enumerate(g['answs'])},
                        'values': [1],
                        'text': g['prefix'],
                        'vars': ['', *(q['text'] for q in g['questions'])]
                    })
                if len(g['questions']) == 1 or all_ones:
                    for i, q in enumerate(g['questions']):
                        json.append({
                            'type': 'one',
                            'num': g['start'] + i,
                            'text': q['full_text'],
                            'vars': ['', *(a['text'] for a in g['answs'])]
                        })
        last_quest = None
        for g in reversed(groups):
            if g['type'] in ('multiselect', 'number'):
                continue
            for q in reversed(g['questions']):
                last_quest = q['id']
                break

        json = {
            'quests': json,
            'params': [{'text': 'У цілому'}],
            'file_where': f"id_file = (SELECT id_file FROM rsrch_files WHERE name = '{base_name}') AND id_worker != 585858",
            'last_quest': last_quest,
        }

        with open(dst_path, 'w', encoding='utf-8') as f:
            hjson.dump(json, f, ensure_ascii=False)


def create_url_file(file, url):
    with open(file, 'w', encoding='utf-8') as f:
        f.write(textwrap.dedent(f'''\
      [{{000214A0-0000-0000-C000-000000000046}}]
      Prop3=19,2
      [InternetShortcut]
      IDList=
      URL={url}
      HotKey=0
      '''))


def transform_html(src_file, dst_dir, options):
    for f in os.listdir(dst_dir):
        if f.startswith('quest') and f.endswith('.html'):
            os.unlink(os.path.join(dst_dir, f))
    with saxonche.PySaxonProcessor(license=False) as proc:
        xsltproc = proc.new_xslt30_processor()
        output = xsltproc.transform_to_string(
            source_file=src_file, stylesheet_file=options.transform_xslt)
        files = output.split('!@#$%^*SEPARATOR*^%$#@!')
        files[-1] = files[-1].replace(f'href="quest{len(files)}.html"',
                                      f'rel="external" href="{options.exit_url}"')
        for i, text in enumerate(files):
            with open(os.path.join(dst_dir, f'quest{i}.html'), 'w',
                      encoding='utf-8') as f:
                f.write(text)
        print(f'Generated {len(files) - 1} quests successfully')


def correct_xml_header(file):
    with open(file, 'r', encoding='utf-8') as f:
        text = f.read()
    if 'https://questionary.iris-psy.org.ua/schema2' in text:
        return
    text = re.sub('<questionary[^>]*?(lang="[^"]+")[^>]*>',
                  '<questionary \\1\n'
                  '             xmlns="https://questionary.iris-psy.org.ua/schema2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"\n'
                  '             xsi:schemaLocation="https://questionary.iris-psy.org.ua/schema2 https://questionary.iris-psy.org.ua/questionary2.xsd">',
                  text)
    with open(file, 'w', encoding='utf-8') as f:
        f.write(text)


def process_file(in_file, options):
    base_name, _ = os.path.splitext(os.path.basename(in_file))
    out_dir = os.path.join(options.output_dir, base_name)
    os.makedirs(out_dir, exist_ok=options.override)
    file = shutil.copy2(in_file, out_dir)
    correct_xml_header(file)
    if not validate(file, options.scheme_file, options.ignore_schema):
        return False
    create_url_file(os.path.join(out_dir, base_name + '.url'),
                    f'{options.base_url}#{base_name}')
    create_url_file(os.path.join(out_dir, 'bulletin.url'),
                    f'{options.bulletin_url}{base_name}')
    create_url_file(os.path.join(out_dir, 'bulletin_recalc.url'),
                    f'{options.bulletin_url}{base_name}&recalc=1')
    extract_header(file, os.path.join(out_dir, 'header.csv'),
                   options.extract_xslt)
    create_sps_labels(file, os.path.join(out_dir, 'labels.sps'),
                      options.extract_xslt)
    create_bulletin_stub(file, os.path.join(out_dir, 'bulletin.hjson'),
                         options.bulletin_xslt, base_name, options.bulletin_all_combinations)
    transform_html(file, out_dir, options)
    if options.remove_input:
        os.remove(in_file)
    return True


@contextlib.contextmanager
def maybe_block_on_error(block_on_error):
    global has_errors
    try:
        yield
    except Exception:
        has_errors = True
        traceback.print_exc()
    finally:
        if has_errors and block_on_error:
            print("Press Enter to continue...", file=sys.stderr)
            input()


def main(options):
    # print(options)
    with maybe_block_on_error(options.block_on_error):
        if options.input_dir:
            for file in os.listdir(options.input_dir):
                if not file.endswith('.xml'):
                    continue
                if not process_file(os.path.join(options.input_dir, file), options):
                    return 1
        else:
            if not process_file(options.input_file, options):
                return 1


if __name__ == '__main__':
    main(parse_args())
