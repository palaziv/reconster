import configparser

config = configparser.ConfigParser()
config.read('mongodb.ini')

connection_string = config['MongoDB']['connection_string']