from selenium import webdriver
from selenium.webdriver.firefox.service import Service
from selenium.webdriver.firefox.options import Options
from webdriver_manager.firefox import GeckoDriverManager
from selenium.webdriver.common.by import By
from colorama import Fore, Back, Style
import os
import sys
import toml

config = None

try:
    config = toml.load("config.toml")
except Exception:
    pass

os.environ['GH_TOKEN'] = config['github_token'] or ''

os.environ['WDM_LOG'] = '0'
options = Options()
options.headless = True
driver = webdriver.Firefox(service=Service(
    GeckoDriverManager().install()), options=options)

url = "https://www.rewe.de/angebote/haan/1940156/rewe-markt-dieker-str-101/"
driver.get(url)

titles = driver.find_elements(By.CLASS_NAME, "cor-offer-title")
found = False
for title in titles:
    if sys.argv[1].lower() in title.text.lower():
        try:
            parent = title.find_element(By.XPATH, '..')
            try:
                percent = parent.find_element(By.CLASS_NAME,
                                              "cor-offer-price-label").text
            except Exception as e:
                print(e)
                percent = None

            price = parent.find_element(By.CLASS_NAME,
                                        "cor-offer-price-amount").text
            if percent:
                print(
                    f"{title.text} is discounted to {Fore.YELLOW}{Back.RED}{price}{Style.RESET_ALL} {Back.YELLOW}{Fore.RED}({percent}){Style.RESET_ALL}")
            else:
                print(
                    f"{title.text} is discounted to {Fore.YELLOW}{Back.RED}{price}")
            found = True
        except Exception as e:
            print(e)
            pass

if not found:
    driver.close()
    print(f"'{sys.argv[1]}' is not discounted")
