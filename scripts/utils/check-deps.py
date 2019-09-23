#!/usr/bin/python3

import sys, shutil, os


def ask_install_deps():
    if os.environ.get('INSTALL_DEPS', False) == '1':
        return True

    answer = input ("You want install missing dependencies ? [y/n] \n").lower()
    possitiveAnswer = ['y', 'yes']
    answerList = ['n', 'no'] + possitiveAnswer
    if answer in answerList:
        if answer in possitiveAnswer:
            return True
        return False
    else:
        print('You need write one of the valid answer which is %s' % answerList)
        ask_install_deps()


def signal_handler():
        print('Script exited')
        sys.exit(0)


def main():
    dependencies = ['jq', 'yq', 'operator-courier', 'operator-sdk', 'kubectl', 'pip3', 'crictl']
    missing = list(filter(lambda dep: shutil.which(dep) is None, dependencies))
    if len(missing) > 0:
        print('You missing these dependencies: %s' % missing)
        install = ask_install_deps()
        if install:
            for dep in missing:
                dir_path = os.path.dirname(os.path.realpath(__file__))
                root_dir = os.path.join(dir_path, '../../')
                os.system('make -C %s dependencies.install.%s' % (root_dir, dep))
    else:
        print('You have all dependencies installed')


if __name__ == "__main__":
    # try:
        main()
    # except KeyboardInterrupt:
    #     pass
    # finally:
    #     signal_handler()


