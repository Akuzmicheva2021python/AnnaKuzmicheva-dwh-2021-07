create database airflights

create schema dbflights

create schema err_dbflights


-- Таблицы измерений
-----------------------------------------
-- Dim_Aircrafts - справочник самолетов
/* 
 *  id  - (суррогатный ключ)    Идентификатор самолета
 *	aircraft_code  Код самолета, IATA
 *	model          Модель самолета
 *	max_range      Максимальная дальность полета, км 
 *  is_current     флаг актуальности
 *  v_current      номер версии
 *  start_ts       дата актуальности
 *  end_ts         дата изменения
 */

CREATE TABLE dbflights.dim_aircrafts (
	ID serial not null PRIMARY key,
	aircraft_code char(3) not null default '000',
	model text not null default '-',
	max_range int4 not null default 0,
	is_current bool not null default true,
	v_current int4 not null default 1,
	start_ts date not null default '2016-01-01'::date,
	end_ts date not null default '2999-12-31'::date );

CREATE TABLE err_dbflights.err_aircraft_rows (
	aircraft_code char(3) NULL,
	model text NULL,
	max_range int4 null,
	err_code_desc text null);
	


-- Dim_Airports - справочник аэропортов
/* 
 *  ID - (суррогатный ключ) Идентификатор аэропорта
 *  airport_code  Код аэропорта
 *  airport_name  Название аэропорта
 *  city          Город
 *  longitude     Координаты аэропорта: долгота
 *  latitude      Координаты аэропорта: широта
 *  timezone      Временная зона аэропорта
 *  
 */	
	

CREATE TABLE dbflights.dim_airports (
	ID serial  PRIMARY key,
	airport_code char(3) not null default '000',
	airport_name text not null default '-',
	city text not null default '-',
	longitude float8 not null default 0,
	latitude float8 not null default 0,
	timezone text not null default '-',
	is_current bool not null default true,
	v_current int4 not null default 1,
	start_ts date not null default '2016-01-01'::date,
	end_ts date not null default '2999-12-31'::date);


CREATE TABLE err_dbflights.err_airport_rows (
	airport_code char(3) NULL,
	airport_name text NULL,
	city text NULL,
	longitude float8 NULL,
	latitude float8 NULL,
	timezone text NULL,
	err_code_desc text null
);
	

----------------------------------------------------------	
-- Dim_Passengers - справочник пассажиров
/* 
 *  id  - (суррогатный ключ)    Идентификатор пассажира
 *  pass_document               номер документа
 *  pass_name                   Имя пассажира
 *  pass_email                  Контакты: email
 *  pass_phone                  Контакты: телефон
 *  
 */

CREATE TABLE dbflights.dim_passengers (
	id serial not null primary key,
	pass_document varchar(20) not null default '-',
	pass_name text NOT null default '-',
	pass_email varchar(50) null default '-',
	pass_phone varchar(20) null default '-',
	is_current bool not null default true,
	v_current int2 not null default 1,
	start_ts date not null default '2016-01-01'::date,
	end_ts date not null default '2999-12-31'::date)
	;


CREATE TABLE err_dbflights.err_passenger_rows (
	id serial not null primary key,
	passenger_id varchar(50) null,
	passenger_name text null,
	contact_data text null,
	dt_start timestamp null,	
	email varchar(250) null,
	phone varchar(200) null,
	err_passenger_row1 text null);





--------------------------------------------------------
--Dim_Tariff - справочник тарифов (Эконом/бизнес и тд)	

CREATE TABLE dbflights.dim_tarif (
	id serial primary KEY,
	tarif_date date not null default '2016-01-01'::date,
	departure_airport char(3) not null default '-',
	arrival_airport char(3) not null default '-',
	aircraft_code char(3) not null default '-',
	tarif_name text not null default '-',
	price numeric(8,2) not null default 0.00,
	is_current bool not null default true,
	v_current int4 not null default 1,
	start_ts date not null default '2016-01-01'::date,
	end_ts date not null default '2999-12-31'::date)
	
CREATE TABLE err_dbflights.err_tarif_rows (
	id serial primary KEY,
	tarif_date date null,
	departure_airport char(3) null,
	arrival_airport char(3) null,
	aircraft_code char(3) null,
	tarif_name text null,
	amount numeric(12,2) null,
	err_code_desc text null);
-------------------------------------------	
-- Dim_Calendar - справочник дат

CREATE TABLE dbflights.dim_canendar (
	id int4 NOT NULL,
	fact_date date NULL,
	ansi_date text NULL,
	day_num int4 NULL,
	week_num int4 NULL,
	month_num int4 NULL,
	year_num int4 NULL,
	year_week int4 NULL,
	week_day int4 NULL,
	quarter_num int4 NULL,
	CONSTRAINT date_pkey PRIMARY KEY (id)
)
--------------------------------------------
-- Наполнение таблицы dbflights.dim_canendar:

with AW ( dt ) as (
		select DD as dt
		from generate_series('2016-01-01'::TIMESTAMP
							,'2022-01-01'::TIMESTAMP
							,'1 day'::interval) DD )
insert into dbflights.dim_canendar (
	id,
	fact_date,
	ansi_date,
	day_num,
	week_num,
	month_num,
	year_num,
	year_week,
	week_day,
	quarter_num
) 
select 
	to_char(dt, 'YYYYMMDD')::int as id,
	dt as fact_date,
	to_char(dt, 'YYYY-MM-DD') as ansi_date,
	date_part('day',dt)::int as day_num,
	date_part('week',dt)::int as week_num,
	date_part('month',dt)::int as month_num,
	date_part('year',dt)::int as year_num,
	date_part('isoyear',dt)::int as year_week,
	date_part('isodow',dt)::int as week_day,
	case 
		when date_part('month',dt)::int between 1 and 3 then 1
		when date_part('month',dt)::int between 4 and 6 then 2
		when date_part('month',dt)::int between 7 and 9 then 3
		when date_part('month',dt)::int between 10 and 12 then 4
		else 0
	end as quarter_num 
from AW as dd
-----------------------------------------------------------------

-- Таблица фактов :
----------------------------------------------------------------	
-- Fact_Flights - содержит совершенные перелеты.
/*
 * id  - (суррогатный ключ)    Идентификатор перелета
 * date_key -                  идентификатор даты перелета
 * pass_id  -                  Идентификатор пассажира
 * flight_id (натуральный ключ)Идентификатор перелета
 * actual_departure            дата-времы вылета
 * actual_arrival              дата-время прилета
 * z_departure                 задержка вылета (секунды)
 * z_arrival                   задержка прилета (секунды)
 * aircraft_id		           Идентификатор самолета
 * departure_airport_id        Идентификатор аэропорта вылета
 * arrival_airport_id          Идентификатор аэропорта прилета
 * fare_conditions             класс обслуживания
 * amount                      стоимость
 * date_ts                     дата записи
 * is_current                  актуальность записи (1-да,0-нет)
 */

CREATE TABLE dbflights.fact_flights (
	id serial primary KEY,
	date_key int not null,
	pass_id int NOT NULL,
	flight_id int NOT NULL,
	actual_departure timestamptz not NULL,
	actual_arrival timestamptz not null,
	z_departure int4 NOT null default 0,
	z_arrival int4 NOT null default 0,
	aircraft_id int NOT NULL,
	departure_airport_id int4 NOT NULL,
	arrival_airport_id int4 NOT NULL,
	fare_conditions varchar(20) not null default 'Не указан',
	amount decimal(12,2) not null default 0.00,
	date_ts timestamp not null default CURRENT_TIMESTAMP,
	is_current bool NOT null default True);
ALTER TABLE dbflights.fact_flights ADD CONSTRAINT fact_flights_dim_aircrafts_fk FOREIGN KEY (aircraft_id) REFERENCES dbflights.dim_aircrafts(id);
ALTER TABLE dbflights.fact_flights ADD CONSTRAINT fact_flights_dim_airports_fk FOREIGN KEY (departure_airport_id) REFERENCES dbflights.dim_airports(id);
ALTER TABLE dbflights.fact_flights ADD CONSTRAINT fact_flights_dim_airports_arrived_fk FOREIGN KEY (arrival_airport_id) REFERENCES dbflights.dim_airports(id);
ALTER TABLE dbflights.fact_flights ADD CONSTRAINT fact_flights_passengers_fk FOREIGN KEY (pass_id) REFERENCES dbflights.dim_passengers(id);
ALTER TABLE dbflights.fact_flights ADD CONSTRAINT fact_flights_calendar_fk FOREIGN KEY (date_key) REFERENCES dbflights.dim_canendar(id);


CREATE TABLE err_dbflights.err_flight_rows (
	flight_id serial NOT NULL,
	ticket_no char(15) null,
	departure_airport char(3) NULL,
	arrival_airport char(3) NULL,
	aircraft_code char(3) NULL,
	actual_departure timestamptz NULL,
	actual_arrival timestamptz null,
	err_code_desc text null);


/* 
with wFL (fl_id, ticket_no, dt) as (
		select 
			f.flight_id as fl_id,
			tf.ticket_no as ticket_no,
			f.actual_departure as dt
		from bookings.flights f 
		left join bookings.ticket_flights tf on tf.flight_id = f.flight_id 
		where 
			f.status = 'Arrived' and 
			f.actual_departure between '2016-09-14'::timestamp and '2016-09-15'::timestamp) , 
wPAS (pass_doc, pass_name) as (
		select distinct 
			t.passenger_id, 
			t.passenger_name
		from bookings.tickets t 
		left join wFL as wfl on wfl.ticket_no = t.ticket_no 
		where not (wfl.ticket_no is null) )
select tt.passenger_id, tt.passenger_name, tt.contact_data 
from bookings.tickets tt 
join wPAS as wpas on tt.passenger_id = wpas.pass_doc and tt.passenger_name = wpas.pass_name
 
  
 with wFL (fl_id, ticket_no, dt_start, dt_end, aircraft_code,
			airport_start, airport_end, klass, amount) as (
		select 
			f.flight_id as fl_id,
			tf.ticket_no as ticket_no,
			f.actual_departure as dt_start,
			f.actual_arrival as dt_end,
			age(f.actual_departure ,f.scheduled_departure ) as start_delay,
			age(f.actual_arrival ,f.scheduled_arrival ) as finish_delay,	
			f.aircraft_code as aircraft_code,
			f.departure_airport as airport_start,
			f.arrival_airport as airport_end,
			tf.fare_conditions as klass,
			tf.amount as amount 			
		from bookings.flights f 
		left join bookings.ticket_flights tf on tf.flight_id = f.flight_id 
		where 
			f.status = 'Arrived' and 
			f.actual_departure between '2016-09-13'::timestamp and '2016-11-14'::timestamp)  
select tt.passenger_id, tt.passenger_name, wfl1.*
from bookings.tickets tt  
join wFL as wfl1 on tt.ticket_no = wfl1.ticket_no
order by tt.passenger_id,tt.passenger_name, wfl1.dt_start;
*/
	
	
	
