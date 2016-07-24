#!/usr/bin/python3
from bs4 import BeautifulSoup
import urllib.request
import argparse
user_name = "ak.38"
start_date = "8"
parser = argparse.ArgumentParser()
parser.add_argument("-v", "--verbose", help="More verbose output", 
                    action="store_true")
args = parser.parse_args()
class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def print_info(msg): 
    if args.verbose: 
        print(bcolors.BOLD + bcolors.OKGREEN + "INFO: " + bcolors.ENDC + msg) 

def print_result(msg): 
    print(bcolors.BOLD + bcolors.OKBLUE + msg + bcolors.ENDC)

def print_error(msg):
    if report_errors == True:
        print("ERROR: " + bcolors.WARNING + msg + bcolors.ENDC)

def get_usasge():
    site_root = "http://mqr.hathway.com/mqsweb/Reports/ServiceUsageReport.asp?USERNAME="
    try:
        print_info("Trying connection")
        raw = urllib.request.urlopen(site_root + user_name).read()
    except urllib.error.HTTPError as e:
        print_error("HTTPError encountered with status code " + str(e.code))

    print_info("Connection successful")
    raw = raw.decode('utf-8')
    get_link = BeautifulSoup(raw, "html.parser").findAll('a')
    print(get_link)

def main():
    get_usasge()

main()
