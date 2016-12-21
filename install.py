#!/usr/bin/env python
# coding=utf-8
import subprocess
import os
import os.path as p
from shutil import copyfile


cross_mark = "✘"
check_mark = "✓"
DIR_OF_THIS_SCRIPT = p.dirname(p.abspath( __file__ ))
HOME_DIR = p.expanduser('~')

def check_program_exists(name):
    p = subprocess.Popen(['/usr/bin/which', name], stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE)
    p.communicate()
    return p.returncode == 0
def Main():
    print("Checking dependencies...")
    print("git: \t\t" + ( check_mark if check_program_exists("git") 
                         else cross_mark ))
    print("Zsh: \t\t" + ( check_mark if check_program_exists("zsh") 
                         else cross_mark ))
    print("tmux: \t\t" + ( check_mark if check_program_exists("tmux") 
                          else cross_mark ))
    print("Oh My Zsh: \t" + ( check_mark 
                             if p.exists(p.join(HOME_DIR, ".oh-my-zsh"))
                           else cross_mark ))
    print("Vim : \t\t" + ( check_mark if check_program_exists("vim") 
                          else cross_mark ))
    print("Installing config")
    if not p.exists(p.join(HOME_DIR, ".vim"))
        os.makedirs(p.join(HOME_DIR, ".vim"))
    copyfile(p.join(DIR_OF_THIS_SCRIPT, "vim", "vimrc"), 
             p.join(HOME_DIR, ".vim"))
    copyfile(p.join(DIR_OF_THIS_SCRIPT, "tmux", "tmux.conf"), 
             p.join(HOME_DIR, ".tmux.conf"))
    copyfile(p.join(DIR_OF_THIS_SCRIPT, "zsh", "zshrc"), 
            p.join(HOME_DIR, ".zshrc"))
    copyfile(p.join(DIR_OF_THIS_SCRIPT, "zsh"))

Main()
