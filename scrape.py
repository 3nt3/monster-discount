from selenium import webdriver
from selenium.webdriver.firefox.service import Service
from selenium.webdriver.firefox.options import Options
from webdriver_manager.firefox import GeckoDriverManager
from selenium.webdriver.common.by import By
from colorama import Fore, Back, Style
import os
import sys

os.environ['WDM_LOG'] = '0'
options = Options()
options.headless = True
driver = webdriver.Firefox(service=Service(
    GeckoDriverManager().install()), options=options)

url = "https://www.rewe.de/angebote/haan/1940156/rewe-markt-dieker-str-101/"
driver.get(url)

titles = driver.find_elements(By.CLASS_NAME, "cor-offer-title")
for title in titles:
    if sys.argv[1].lower() in title.text.lower():
        parent = title.find_element(By.XPATH, '..')
        percent = parent.find_element(By.CLASS_NAME,
                                      "cor-offer-price-label").text
        price = parent.find_element(By.CLASS_NAME,
                                    "cor-offer-price-amount").text
        print(
            f"{title.text} if discounted to {Fore.YELLOW}{Back.RED}{price}{Style.RESET_ALL} {Back.YELLOW}{Fore.RED}({percent})")

driver.close()
