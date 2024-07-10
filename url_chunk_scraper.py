#NOTE IF EDITING IN THE FUTURE

#MUST INSTALL SELENIUM AND HAVE CHROMEDRIVER IN YOUR BIN FOLDER
#CHECK XPATHING ON carsanddriver.com

from time import time
from time import sleep
import csv
import string
import pprint
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.support import expected_conditions as EC

pp = pprint.PrettyPrinter(indent=4)

BASE_URL = "https://www.caranddriver.com"


#I have no idea what options is doing here.
options = Options()
options.add_argument("--no-sandbox")
options.add_argument("start-maximized")
options.add_experimental_option("detach", True)
options.add_experimental_option("excludeSwitches", ["enable-logging"])

#Pathing is based on your chromedrievr
path = Service("/usr/local/bin/chromedriver")  # Updated path for Mac
driver = webdriver.Chrome(service=path, options=options)
driver.get(BASE_URL)
wait = WebDriverWait(driver, 5)

#Bro what is this?
#Open Menu selects "Research Cars" at the top of the webpage
def openMenu():
    menu = wait.until(EC.element_to_be_clickable((By.XPATH, '//*[@id="__next"]/nav/div/div[1]/button')))
    menu.click()

def getMakes():
    make_field = wait.until(EC.element_to_be_clickable((By.XPATH, '//*[@id="P0-3"]/div[2]/select')))
    make_field.click()
    makes = wait.until(EC.presence_of_all_elements_located((By.XPATH, '//*[@id="P0-3"]/div[2]/select/option')))
    makes_text = [make.text for make in makes[1:]]  # Exclude the first element which is usually a placeholder or header
    make_field.click()  # Click again to close the dropdown if needed
    return makes_text

def getModels(make_index=0):
    makes = getMakes()
    make_name = makes[make_index]
    
    make_field = wait.until(EC.element_to_be_clickable((By.XPATH, '//*[@id="P0-3"]/div[3]/select')))
    make_field.click()
    make_option = makes[make_index + 1]  # Adjust for proper indexing
    make_option.click()
    
    model_field = wait.until(EC.element_to_be_clickable((By.XPATH, '//*[@id="P0-3"]/div[3]/select')))
    model_field.click()
    models = wait.until(EC.presence_of_all_elements_located((By.XPATH, '//*[@id="P0-3"]/div[3]/select/option')))
    models_text = [model.text for model in models[1:]]  # Exclude the first element which is usually a placeholder or header
    model_field.click()  # Click again to close the dropdown if needed
    
    return [make_name] + models_text

#I understand what this is doing, this just loops through each make and model and adds it to the csv
def getAllModels():
    makes = getMakes()
    for i in range(len(makes)):
        get_models = getModels(i)
        make = get_models[0]
        models_local = get_models[1:]
        print(make, models_local)
        with open('models.csv', 'a', newline='\r\n') as file:
            writer = csv.writer(file)
            for i in range(len(models_local)):
                writer.writerow([make, models_local[i]])
    return

#This creats the rest of the csv/formatting
def createModelUrl():
    model_url_strings = []

    with open('models.csv', 'r', newline='\r\n') as file:
        reader = csv.reader(file)
        for row in reader:
            make = row[0].lower().replace(' ', '-')
            model = row[1]
            model = model.split(' ')
            if '/' in model:
                model.remove('/')
            else:
                pass
            model = '-'.join(model)
            model = model.replace('.', '')
            model = model.lower()
            model_url = '/'.join([make, model])
            model_packet = [make, model, model_url]
            model_url_strings.append(model_packet)

    del model_url_strings[0]
    print(model_url_strings)

    with open('model-urls.csv', 'w', newline='\r\n') as file:
        writer = csv.writer(file)
        writer.writerow(['make', 'model', 'model_url'])
        for i in range(len(model_url_strings)):
            writer.writerow(model_url_strings[i])
    return

def createSpecUrl():
    model_url_strings = []

    with open('models.csv', 'r', newline='\r\n') as file:
        reader = csv.reader(file)
        for row in reader:
            make = row[0].lower().replace(' ', '-')
            model = row[1]
            model = model.split(' ')
            if '/' in model:
                model.remove('/')
            else:
                pass
            model = '-'.join(model)
            model = model.replace('.', '')
            model = model.lower()
            model_url = '/'.join([make, model, 'specs'])
            model_packet = [make, model, model_url]
            model_url_strings.append(model_packet)

    del model_url_strings[0]
    print(model_url_strings)

    with open('model-urls.csv', 'w', newline='\r\n') as file:
        writer = csv.writer(file)
        writer.writerow(['make', 'model', 'model_url'])
        for i in range(len(model_url_strings)):
            writer.writerow(model_url_strings[i])
    return

def getYears():
    with open('model-year-urls.csv', 'w', newline='\r\n') as to_write:
        writer = csv.writer(to_write)
        writer.writerow(['make', 'model', 'year'])
    
    with open('model-urls.csv', 'r', newline='\r\n') as file:
        reader = csv.reader(file)
        next(reader)  # Skip header
        for row in reader:
            try:
                driver.get(BASE_URL + '/' + row[2])
                year_field = wait.until(EC.element_to_be_clickable((By.XPATH, '//*[@id="P0-3"]/div[4]/select')))
                year_field.click()
                years = wait.until(EC.presence_of_all_elements_located((By.XPATH, '//*[@id="P0-3"]/div[4]/select/option')))
                for year in years[1:]:  # Exclude the first element
                    year_text = year.text
                    year.click()
                    
                        
                        # Now write to CSV or do further processing
                    with open('model-year-urls.csv', 'a', newline='\r\n') as to_write:
                        writer = csv.writer(to_write)
                        writer.writerow([row[0], row[1], year_text])
            except TimeoutException:
                print("Timeout while getting years and styles.")
                
                

def createStyleUrl():
    style_url_strings = []

    with open('style-urls.csv', 'w', newline='\r\n') as file:
        writer = csv.writer(file)
        writer.writerow(['make', 'model', 'year', 'style', 'style_string', 'style_url'])

    with open('model-year-urls.csv', 'r', newline='\r\n') as file:
        reader = csv.reader(file)
        for row in reader:
           make = row[0]
           model = row[1]
           year = row[2]
           style = row[3]
           style_string = row[4]
           full_url = '/'.join([BASE_URL, make, model, 'specs', year, style_string])
           style_url_packet = [make, model, year, style, style_string, full_url]
           style_url_strings.append(style_url_packet)

    del style_url_strings[0]
#         pp.pprint(style_url_strings)
    with open('style-urls.csv', 'a', newline='\r\n') as file:
        writer = csv.writer(file)
        for i in range(len(style_url_strings)):
            writer.writerow(style_url_strings[i])

def getTrims():
    wait = WebDriverWait(driver, 3)

    with open('trim-urls.csv', 'w', newline='\r\n') as file:
        writer = csv.writer(file)
        writer.writerow(['make', 'model', 'year', 'style', 'style_string', 'trim_text', 'trim_value'])

    with open('style-urls.csv', 'r', newline='\r\n') as file:
        reader = csv.reader(file)
        urls = list(reader)
        del urls[0]
        trim_packets = []
        for row in urls:
            sleep(1)
            try:
                driver.get(row[5])
                make = row[0]
                model = row[1]
                year = row[2]
                style = row[3]
                style_string = row[4]
                print(style_string)
                trim_field = wait.until(EC.element_to_be_clickable((By.XPATH, '//*[@id="trimSelect"]')))
                trim_field.click()
                trims = wait.until(EC.element_to_be_clickable((By.XPATH, '//*[@id="trimSelect"]/option[1]')))
                trims = driver.find_elements(By.XPATH, '//*[@id="trimSelect"]/option')
                del trims[0]
                for trim in range(len(trims)):
                    text_trim = trims[trim].text
                    trim_value = trims[trim].get_attribute("value")
                    trim_packet = [make, model, year, style, style_string, text_trim, trim_value]
                    print(trim_packet)
                    trim_packets.append(trim_packet)
            except TimeoutException:
                print("No trims")

    with open('trim-urls.csv', 'a', newline='\r\n') as file:
        writer = csv.writer(file)
        for i in range(len(trim_packets)):
            writer.writerow(trim_packets[i])

def createTrimUrl():
    trim_url_strings = []

    with open('full-urls.csv', 'w', newline='\r\n') as file:
        writer = csv.writer(file)
        writer.writerow(['make', 'model', 'year', 'style', 'style_string', 'trim', 'trim_value', 'full_url'])

    with open('trim-urls.csv', 'r', newline='\r\n') as file:
        reader = csv.reader(file)
        for row in reader:
           make = row[0]
           model = row[1]
           year = row[2]
           style = row[3]
           style_string = row[4]
           trim = row[5]
           trim_value = row[6]
           full_url = '/'.join([BASE_URL, make, model, 'specs', year, style_string, trim_value])
           full_url_packet = [make, model, year, style, style_string, trim, trim_value, full_url]
           trim_url_strings.append(full_url_packet)

    del trim_url_strings[0]

    with open('full-urls.csv', 'a', newline='\r\n') as file:
        writer = csv.writer(file)
        for i in range(len(trim_url_strings)):
            writer.writerow(trim_url_strings[i])


def main():

    with open('models.csv', 'w', newline='\r\n') as file:
        writer = csv.writer(file)
        writer.writerow(['make', 'model'])

    openMenu()
    getAllModels()
#    createSpecUrl()
#    getYearsAndStyles()
#    createStyleUrl()
#    getTrims()
#    createTrimUrl()
    driver.close()


if __name__ == '__main__':
    start = float(time()) # Timing script because why not.
    main()
    end = float(time())
    print('-----------------------------------------------\ncompleted in:', (end-start)) # More formatting. Same drill.


