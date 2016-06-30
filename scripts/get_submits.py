#!/usr/bin/python3
import urllib.request
import sys
import json
import pprint
from bs4 import BeautifulSoup
import argparse

report_errors = True #Change to false to use as a module
count = 0 #Global variable to keep number of submissions taken in 
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

def get_max_pages(problem_code, contest_code, verbose=False):
    site_root = "https://www.codechef.com"
    try:
        print_info("Trying connection")
        raw = urllib.request.urlopen(site_root +
                            "/ssubmission/prob?page=" + "1" + 
                                            "&pcode=" + problem_code +
                                            "&ccode=" + contest_code).read()
    except urllib.error.HTTPError as e:
        #We retry forever in case of 503
        print_error("HTTPError encountered with status code " + str(e.code))
        if e.code == 503:
            return get_max_pages(problem_code, contest_code, verbose)
        else:
            print_error("""Check problem_code, contest_code or your internet
                        connection""")
            return {}


    print_info("Connection successful")
    raw = raw.decode('utf-8')
    return json.loads(raw)["max_page"]

def get_submits(problem_code, contest_code, page_no="1"):
    # Returns the submissions as a dict with the relevant data-id as the key
    site_root = "https://www.codechef.com"
    try:
        print_info("Trying connection")
        raw = urllib.request.urlopen(site_root +
                            "/ssubmission/prob?page=" + page_no + 
                                            "&pcode=" + problem_code +
                                            "&ccode=" + contest_code).read()
    except urllib.error.HTTPError as e:
        #We retry forever in case of 503
        print_error("HTTPError encountered with status code " + str(e.code))
        if e.code == 503:
            return get_submits(problem_code, contest_code, page_no)
        else:
            print_error("""Check problem_code, contest_code or your internet connection""")
            return {}

    print_info("Connection successful")
    raw = raw.decode('utf-8')
    submission_html = json.loads(raw)["content"]
    submit_list = BeautifulSoup(submission_html, "html.parser").findAll("tr")
    submit_list.pop(0)
    final_data = []
    for sub in submit_list:
        sub_dict = {}
        sub_tag = sub.findAll("td")
        if len(sub_tag) != 5:
             print_error("""Check problem_code, contest_code or your internet connection""")
             break
        sub_dict["user"]        = sub_tag[0].text
        sub_dict["score/time"]  = sub_tag[1].text
        sub_dict["mem"]         = sub_tag[2].text
        sub_dict["lang"]        = sub_tag[3].text
        sub_dict["solution"]    = site_root + sub_tag[4].findAll("a")[0]["href"]
        final_data.append(sub_dict)
    return final_data

# CLI for usage
parser = argparse.ArgumentParser()
parser.add_argument("problem_code", help="Problem code for the problem",
                    type=str)
parser.add_argument("contest_code", help="Contest code for the problem",
                    type=str)
parser.add_argument("-p", help="""Page number of the result page, if not
                    specified, gives the first page""",
                    metavar="page_no")
parser.add_argument("-n", help="""Number of submissions to show""", type=int,
                    metavar="num_submits")
parser.add_argument("-l", help="""Only show submissions in language_name""",
                    metavar="language_name")
parser.add_argument("-O", help="""Order by 'name', 'time' or 'lang'""",
                     type=str, choices=["name", "time", "lang"])
parser.add_argument("--max_pages_only", help="Give max number of pages and exit",
                    action="store_true")
parser.add_argument("-o", help="Output to file_name", metavar="file_name")
parser.add_argument("-v", "--verbose", help="More verbose output", 
                    action="store_true")
args = parser.parse_args()
def main():
    if args.verbose :
        print_info("Verbose mode on")

    if args.max_pages_only :
        ans = str(get_max_pages(args.problem_code, args.contest_code))
        print("Maximum pages in submission set : ", end="")
        print_result(ans)
        return

    if args.p : 
        submits = get_submits(args.problem_code, args.contest_code, args.p)
        for row in submits:
            pprint.pprint(row)
        return

    if args.l :
        max_pages = get_max_pages(args.problem_code, args.contest_code)
        def scan():
            for cur_page in range(max_pages):
                data = get_submits(args.problem_code, args.contest_code, str(cur_page))
                for elem in data:
                    if elem["lang"] == args.l:
                        print(elem)
                        return

                if args.verbose:
                    print(cur_page, end= "\r")
                    sys.stdout.flush()
            print_info("No such result")
        scan()
        return
    if args.n :
        max_pages = get_max_pages(args.problem_code, args.contest_code)
        def scan():
            for cur_page in range(max_pages):
                data = get_submits(args.problem_code, args.contest_code, str(cur_page))
                for elem in data:
                    print(elem)
                    global count
                    count = count + 1
                    if count == args.n:
                        return
            print_info("Not enough results")
        scan()
        return

main()

