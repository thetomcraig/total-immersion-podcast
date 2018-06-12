import sys
from shutil import copyfile

title_stub = 'TITLE'
summary_stub = 'SUMMARY'
link_stub = 'LINK'
date_stub = 'DATE'


def main():
    new_hunk = ''
    filename = './episode_hunk.txt'
    backup = filename + '.bak'
    copyfile(filename, backup)

    title = sys.argv[1]
    summary = sys.argv[2]
    link = sys.argv[3]
    date = sys.argv[4]

    with open(filename, 'r') as f:
        for line in f.readlines():
            if title_stub in line:
                line = line.replace(title_stub, title)
            if summary_stub in line:
                line = line.replace(summary_stub, summary)
            if link_stub in line:
                line = line.replace(link_stub, link)
            if date_stub in line:
                line = line.replace(date_stub, date)
            new_hunk = new_hunk + line

    print new_hunk

if __name__ == "__main__":
    main()
