# PYTHON CODE TO SCRAPE 2010 CENSUS BLOCK SHAPE FILES FROM INEGI WEBSITE
# Written by Sean Higgins, shiggins@tulane.edu
# Created 26aug2015

# PACKAGES
from bs4 import BeautifulSoup as bs # scraping
import urllib2
import os # for shell commands like change directory
import re # regular expressions
import glob # for list of files in a directory; see http://goo.gl/rVNp22

# DIRECTORIES
base = 'C:/Dropbox/FinancialInclusion' # !change! if using a different computer
main = base + '/_shps/_2010' 
os.chdir(main)
already = glob.glob('*.zip')

# LOCALS
# NOTE THE STATES INCLUDED IN ENCELURB 2009 ARE 			 
                       # 04 CAMPECHE |        182        2.90        2.90
                         # 06 COLIMA |         40        0.64        3.54
                        # 07 CHIAPAS |        993       15.83       19.37
                     # 11 GUANAJUATO |        135        2.15       21.52
                       # 12 GUERRERO |        790       12.60       34.12
                        # 13 HIDALGO |         33        0.53       34.65
                         # 15 MEXICO |        575        9.17       43.81
            # 16 MICHOACAN DE OCAMPO |        416        6.63       50.45
                        # 17 MORELOS |        452        7.21       57.65
                         # 21 PUEBLA |        200        3.19       60.84
                # 24 SAN LUIS POTOSI |          3        0.05       60.89
                         # 26 SONORA |         17        0.27       61.16
                        # 27 TABASCO |        361        5.76       66.92
                     # 28 TAMAULIPAS |        254        4.05       70.97
                       # 29 TLAXCALA |         82        1.31       72.27
                       # 30 VERACRUZ |         72        1.15       73.42
# 30 VERACRUZ DE IGNACIO DE LA LLAVE |      1,667       26.58      100.00

base_url = 'http://internet.contenidos.inegi.org.mx/contenidos/Productos/prod_serv/contenidos/espanol/bvinegi/productos/geografia/urbana/SHP'
spacereplace = r'%2520'
base_state_url = 'http://buscador.inegi.org.mx/search?client=ProductosR&proxystylesheet=ProductosR&num=1000&getfields=*&sort=meta:Titulo:A:E:::D&entsp=a__inegi_politica_p72&lr=lang_es%7Clang_en&oe=UTF-8&ie=UTF-8&entqr=3&filter=0&ip=10.210.100.253&site=ProductosBuscador&tlen=260&ulang=es&access=p&entqrm=0&ud=1&q=Cartograf%C3%ADa+Geoestad%C3%ADstica+2010+inmeta:Entidad%3D'
next_state_url = '&dnavs=inmeta:Entidad%3D'

state_names = [
	'Campeche',
	'Colima',
	'Chiapas',
	'Guanajuato',
	'Guerrero',
	'Hidalgo',
	'Mexico',
	'Michoacan_de_Ocampo',
	'Morelos',
	'Puebla',
	'San_Luis_Potosi',
	'Sonora',
	'Tabasco',
	'Tamaulipas',
	'Tlaxcala',
	'Veracruz_de_Ignacio_de_la_Llave'	
]

# PRELIMINARY PROGRAMS
def get_shp_zip(statename):
	print statename
	myurl = base_state_url + statename.replace('_',spacereplace) + next_state_url + statename.replace('_',spacereplace)
	resp = urllib2.urlopen(myurl)
	
	# scrape 
	soup = bs(resp.read())
	links = soup.find_all('a')
	
	upcs = []
	
	for link in links:
		longer_url = link.get('href')
		try:
			if "upc=" not in longer_url: continue
			upc = re.sub(r'.*upc=',"",longer_url)
			upcs.append(upc)
		except: # was getting a field called 'None' in Veracruz so had to add this part
			print "Error with %s" % longer_url
			continue
	
	for upc_ in upcs:
		full_link   = base_url + '/'   + statename + '/' + upc_ + '_s.zip'
		full_link_2 = base_url + '_2/' + statename + '/' + upc_ + '_s.zip'
		try: 
			myzip = urllib2.urlopen(full_link)
			folder = "1"
		except: 
			try: 
				myzip = urllib2.urlopen(full_link_2)
				folder = "2"			
			except: 
				print "error downloading %s" % upc_ # could be rural
				continue
		myzipname = folder + '/' + upc_ + '_s.zip'
		if myzipname in already: continue # break out of loop if already downloaded
		thezip = myzip.read()
		with open(myzipname,'wb') as code:
			code.write(thezip)

# LET'S GET SOME SHAPE FILES
for name_ in state_names:
	get_shp_zip(name_)

# UNZIP
# allzips = glob.glob
