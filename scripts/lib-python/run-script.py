#!/usr/bin/python3
import sys
import subprocess
import getopt
import time


class bcolors:
    """Terminal colors"""
    OK = "\033[0;32m"
    WARN = "\033[0;33m"
    ERR = "\033[0;31m"
    NC = "\033[0m"


def animate(process, name):
    """Simple processing animation"""
    while True:
        chars = "\\|/-\\|/-"
        for char in chars:
            sys.stdout.write(bcolors.WARN + '\rProcessing {} {}'.format(name, char) + bcolors.NC)
            sys.stdout.flush()
            p_status = process.poll()
            if p_status is not None:
                sys.stdout.write('\r' + ' ' * 100)
                sys.stdout.flush()

                return p_status
            time.sleep(0.2)


def main(argv):
    verbosity = 0
    break_cmd = 0

    try:
        opts, args = getopt.getopt(argv, "vb", ["verbosity=", "break="])
    except getopt.GetoptError:
        sys.exit(2)

    for opt in opts:
        if opt in ("-v", "--verbosity"):
            verbosity = 1
        elif opt in ("-b", "--break"):
            break_cmd = 1

    if len(args) < 2:
        sys.exit(0)

    command = args[0]
    name = args[1]

    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    p_status = animate(process, name)

    err_exit = None
    if p_status == 0:
        print(bcolors.OK + '\rOK' + bcolors.NC)
    else:
        print(bcolors.ERR + '\rFAILED' + bcolors.NC)
        if break_cmd == 1:
            err_exit = 1

    (output, err) = process.communicate()

    if verbosity == 1:
        print(output.decode("utf-8"), end='')
        print(err.decode('utf-8'), end='')

    if err_exit:
        sys.exit(1)


if __name__ == "__main__":
    main(sys.argv[1:])
