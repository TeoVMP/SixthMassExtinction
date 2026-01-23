# TimeSystem.gd
# Sistema de tiempo/calendario del juego
# Inicio: 20 de septiembre de 2028 (nacimiento del protagonista)

extends Node
class_name TimeSystem

# Señales
signal day_passed(year: int, month: int, day: int)
signal month_passed(year: int, month: int)
signal year_passed(year: int)
signal time_teleported(days_forward: int, reason: String)

# Fecha actual
var current_year: int = 2028
var current_month: int = 9
var current_day: int = 20
var days_passed: int = 0

# Meses del año (días por mes)
var days_per_month = {
	1: 31, 2: 28, 3: 31, 4: 30, 5: 31, 6: 30,
	7: 31, 8: 31, 9: 30, 10: 31, 11: 30, 12: 31
}

# Años bisiestos
var leap_years = [2028, 2032, 2036]

func _ready():
	print("📅 TimeSystem iniciado - Fecha: ", get_date_string())

func get_date_string() -> String:
	"""Retorna la fecha actual como string"""
	return str(current_day) + "/" + str(current_month) + "/" + str(current_year)

func is_leap_year(year: int) -> bool:
	"""Verifica si un año es bisiesto"""
	return year in leap_years or (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)

func get_days_in_month(month: int, year: int) -> int:
	"""Obtiene los días de un mes considerando años bisiestos"""
	if month == 2 and is_leap_year(year):
		return 29
	return days_per_month[month]

func advance_day():
	"""Avanza un día en el calendario"""
	current_day += 1
	days_passed += 1
	
	# Verificar si pasamos de mes
	var days_in_month = get_days_in_month(current_month, current_year)
	if current_day > days_in_month:
		current_day = 1
		advance_month()
	else:
		day_passed.emit(current_year, current_month, current_day)

func advance_month():
	"""Avanza un mes en el calendario"""
	current_month += 1
	if current_month > 12:
		current_month = 1
		advance_year()
	month_passed.emit(current_year, current_month)

func advance_year():
	"""Avanza un año en el calendario"""
	current_year += 1
	year_passed.emit(current_year)

func teleport_time(days: int, reason: String = ""):
	"""Teletransporta el tiempo hacia adelante (solo positivo)"""
	if days <= 0:
		return
	
	for i in range(days):
		advance_day()
	
	time_teleported.emit(days, reason)
	print("⏰ Teletransportación temporal: +", days, " días. Razón: ", reason)
	print("   Nueva fecha: ", get_date_string())

func get_days_until_year(target_year: int) -> int:
	"""Calcula días hasta un año objetivo"""
	var days = 0
	var temp_year = current_year
	var temp_month = current_month
	var temp_day = current_day
	
	while temp_year < target_year:
		days += get_days_in_month(temp_month, temp_year) - temp_day + 1
		temp_day = 1
		temp_month += 1
		if temp_month > 12:
			temp_month = 1
			temp_year += 1
	
	return days

func get_days_until_date(target_year: int, target_month: int, target_day: int) -> int:
	"""Calcula días hasta una fecha específica"""
	var days = 0
	var temp_year = current_year
	var temp_month = current_month
	var temp_day = current_day
	
	while temp_year < target_year or (temp_year == target_year and temp_month < target_month) or (temp_year == target_year and temp_month == target_month and temp_day < target_day):
		days += 1
		temp_day += 1
		var days_in_month = get_days_in_month(temp_month, temp_year)
		if temp_day > days_in_month:
			temp_day = 1
			temp_month += 1
			if temp_month > 12:
				temp_month = 1
				temp_year += 1
	
	return days
















