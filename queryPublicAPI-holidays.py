# https://rapidapi.com/zh/theapiguy/api/public-holiday

import requests
import sys
import time

def get_holidays(year: int) -> object:
    url = f"https://public-holiday.p.rapidapi.com/{year}/US"
    headers = {
        'x-rapidapi-key': "<your key>",
        'x-rapidapi-host': "public-holiday.p.rapidapi.com"
        }

    return requests.request("GET", url, headers=headers)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("please use format: holidays.py from_year to_year")
        sys.exit(1)
    from_year = int(sys.argv[1])
    to_year = int(sys.argv[2])
    # output = open('output.json', 'w')
    output = open('output.csv', 'w')
    output.write('date,local_name\n')
    start_time = time.time()
    for year in range(from_year,to_year):
        # output.write(get_holidays(year).text)
        
        holidays = get_holidays(year).json()
        for i in range(len(holidays)):
            holiday = holidays[i]
            date = holiday['date']
            local_name = holiday['localName']
            if ',' in local_name:
                local_name = ''.join(local_name.split(','))
            row = f'{date},{local_name}\n'
            output.write(row)
        # print(holiday[0]['date'])
    
    print(f'total time spend: {time.time() - start_time}s')
    output.close()  