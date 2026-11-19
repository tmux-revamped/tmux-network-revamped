#!/bin/sh
# shellcheck disable=SC2034

[ -n "${NETWORK_REVAMPED_STATE_LOADED:-}" ] && return 0
NETWORK_REVAMPED_STATE_LOADED=1

NETWORK_REVAMPED_SETTINGS='popup_key	M-e
interface
interval	2
precision	1
smoothing	0
render	jobs
ping_enabled	0
public_ip_enabled	0
online_enabled	0
vpn_interval	30
vpn_name_interval	30
ip_interval	30
connections_interval	30
wifi_interval	30
ssid_interval	30
online_interval	30
ping_interval	15
public_ip_interval	300
speed_format	%s %s
ping_format	%sms
wifi_format	%sdBm
online_up_text	on
online_down_text	off
icons	ascii
fixed_width	off
download_label
upload_label
speed_label
vpn_label
vpn_name_label
ip_label
wifi_label
ssid_label
connections_label
ping_label
public_ip_label
online_label
download_width
upload_width
speed_width
vpn_width
vpn_name_width
ip_width
wifi_width
ssid_width
connections_width
ping_width
public_ip_width
online_width
medium_thresh	100
high_thresh	1000
low_fg_color
medium_fg_color
high_fg_color
low_bg_color
medium_bg_color
high_bg_color'
NETWORK_REVAMPED_NAMES='popup_key interface interval precision smoothing render ping_enabled public_ip_enabled online_enabled vpn_interval vpn_name_interval ip_interval connections_interval wifi_interval ssid_interval online_interval ping_interval public_ip_interval speed_format ping_format wifi_format online_up_text online_down_text icons fixed_width download_label upload_label speed_label vpn_label vpn_name_label ip_label wifi_label ssid_label connections_label ping_label public_ip_label online_label download_width upload_width speed_width vpn_width vpn_name_width ip_width wifi_width ssid_width connections_width ping_width public_ip_width online_width medium_thresh high_thresh low_fg_color medium_fg_color high_fg_color low_bg_color medium_bg_color high_bg_color'
NETWORK_REVAMPED_CARRIED='interface interval precision smoothing render ping_enabled public_ip_enabled online_enabled vpn_interval vpn_name_interval ip_interval connections_interval wifi_interval ssid_interval online_interval ping_interval public_ip_interval speed_format ping_format wifi_format online_up_text online_down_text icons fixed_width download_label upload_label speed_label vpn_label vpn_name_label ip_label wifi_label ssid_label connections_label ping_label public_ip_label online_label download_width upload_width speed_width vpn_width vpn_name_width ip_width wifi_width ssid_width connections_width ping_width public_ip_width online_width medium_thresh high_thresh low_fg_color medium_fg_color high_fg_color low_bg_color medium_bg_color high_bg_color'
NETWORK_REVAMPED_LIVE='download upload total down_smooth up_smooth sample_ms rx_raw tx_raw download_ts download_lock download_lock_ts vpn vpn_ts vpn_name vpn_name_ts ip ip_ts connections connections_ts wifi wifi_ts ssid ssid_ts ping ping_ts public_ip public_ip_ts online online_ts published'
NETWORK_REVAMPED_S_popup_key='M-e'
NETWORK_REVAMPED_S_interface=''
NETWORK_REVAMPED_S_interval='2'
NETWORK_REVAMPED_S_precision='1'
NETWORK_REVAMPED_S_smoothing='0'
NETWORK_REVAMPED_S_render='jobs'
NETWORK_REVAMPED_S_ping_enabled='0'
NETWORK_REVAMPED_S_public_ip_enabled='0'
NETWORK_REVAMPED_S_online_enabled='0'
NETWORK_REVAMPED_S_vpn_interval='30'
NETWORK_REVAMPED_S_vpn_name_interval='30'
NETWORK_REVAMPED_S_ip_interval='30'
NETWORK_REVAMPED_S_connections_interval='30'
NETWORK_REVAMPED_S_wifi_interval='30'
NETWORK_REVAMPED_S_ssid_interval='30'
NETWORK_REVAMPED_S_online_interval='30'
NETWORK_REVAMPED_S_ping_interval='15'
NETWORK_REVAMPED_S_public_ip_interval='300'
NETWORK_REVAMPED_S_speed_format='%s %s'
NETWORK_REVAMPED_S_ping_format='%sms'
NETWORK_REVAMPED_S_wifi_format='%sdBm'
NETWORK_REVAMPED_S_online_up_text='on'
NETWORK_REVAMPED_S_online_down_text='off'
NETWORK_REVAMPED_S_icons='ascii'
NETWORK_REVAMPED_S_fixed_width='off'
NETWORK_REVAMPED_S_download_label=''
NETWORK_REVAMPED_S_upload_label=''
NETWORK_REVAMPED_S_speed_label=''
NETWORK_REVAMPED_S_vpn_label=''
NETWORK_REVAMPED_S_vpn_name_label=''
NETWORK_REVAMPED_S_ip_label=''
NETWORK_REVAMPED_S_wifi_label=''
NETWORK_REVAMPED_S_ssid_label=''
NETWORK_REVAMPED_S_connections_label=''
NETWORK_REVAMPED_S_ping_label=''
NETWORK_REVAMPED_S_public_ip_label=''
NETWORK_REVAMPED_S_online_label=''
NETWORK_REVAMPED_S_download_width=''
NETWORK_REVAMPED_S_upload_width=''
NETWORK_REVAMPED_S_speed_width=''
NETWORK_REVAMPED_S_vpn_width=''
NETWORK_REVAMPED_S_vpn_name_width=''
NETWORK_REVAMPED_S_ip_width=''
NETWORK_REVAMPED_S_wifi_width=''
NETWORK_REVAMPED_S_ssid_width=''
NETWORK_REVAMPED_S_connections_width=''
NETWORK_REVAMPED_S_ping_width=''
NETWORK_REVAMPED_S_public_ip_width=''
NETWORK_REVAMPED_S_online_width=''
NETWORK_REVAMPED_S_medium_thresh='100'
NETWORK_REVAMPED_S_high_thresh='1000'
NETWORK_REVAMPED_S_low_fg_color=''
NETWORK_REVAMPED_S_medium_fg_color=''
NETWORK_REVAMPED_S_high_fg_color=''
NETWORK_REVAMPED_S_low_bg_color=''
NETWORK_REVAMPED_S_medium_bg_color=''
NETWORK_REVAMPED_S_high_bg_color=''
NETWORK_REVAMPED_S_download=''
NETWORK_REVAMPED_S_upload=''
NETWORK_REVAMPED_S_total=''
NETWORK_REVAMPED_S_down_smooth=''
NETWORK_REVAMPED_S_up_smooth=''
NETWORK_REVAMPED_S_sample_ms=''
NETWORK_REVAMPED_S_rx_raw=''
NETWORK_REVAMPED_S_tx_raw=''
NETWORK_REVAMPED_S_download_ts=''
NETWORK_REVAMPED_S_download_lock=''
NETWORK_REVAMPED_S_download_lock_ts=''
NETWORK_REVAMPED_S_vpn=''
NETWORK_REVAMPED_S_vpn_ts=''
NETWORK_REVAMPED_S_vpn_name=''
NETWORK_REVAMPED_S_vpn_name_ts=''
NETWORK_REVAMPED_S_ip=''
NETWORK_REVAMPED_S_ip_ts=''
NETWORK_REVAMPED_S_connections=''
NETWORK_REVAMPED_S_connections_ts=''
NETWORK_REVAMPED_S_wifi=''
NETWORK_REVAMPED_S_wifi_ts=''
NETWORK_REVAMPED_S_ssid=''
NETWORK_REVAMPED_S_ssid_ts=''
NETWORK_REVAMPED_S_ping=''
NETWORK_REVAMPED_S_ping_ts=''
NETWORK_REVAMPED_S_public_ip=''
NETWORK_REVAMPED_S_public_ip_ts=''
NETWORK_REVAMPED_S_online=''
NETWORK_REVAMPED_S_online_ts=''
NETWORK_REVAMPED_S_published=''
NETWORK_REVAMPED_METRICS='download upload speed fg_color bg_color vpn vpn_name ip wifi ssid connections ping public_ip online'
NETWORK_REVAMPED_DEFAULT_POPUP_KEY='M-e'
NETWORK_REVAMPED_DEFAULT_INTERVAL=2
NETWORK_REVAMPED_DEFAULT_PRECISION=1
NETWORK_REVAMPED_DEFAULT_PROBE=30
NETWORK_REVAMPED_DEFAULT_PING=15
NETWORK_REVAMPED_DEFAULT_PUBLIC_IP=300
NETWORK_REVAMPED_DEFAULT_MEDIUM=100
NETWORK_REVAMPED_DEFAULT_HIGH=1000
NETWORK_REVAMPED_RATE_NATURAL=8
NETWORK_REVAMPED_PING_NATURAL=5
NETWORK_REVAMPED_PING_HOST='8.8.8.8'
NETWORK_REVAMPED_PUBLIC_IP_URL='https://icanhazip.com'
NETWORK_REVAMPED_ONLINE_URL='https://www.gstatic.com/generate_204'
NETWORK_REVAMPED_POPUP_WIDTH='70%'
NETWORK_REVAMPED_POPUP_HEIGHT='80%'
NETWORK_REVAMPED_POPUP_SINCE=3.2
NETWORK_REVAMPED_NOTES_SINCE=3.1
NETWORK_REVAMPED_EMPTY='network-revamped-empty-argument'
NETWORK_REVAMPED_TMUX=''
NETWORK_REVAMPED_NOTES=0
NETWORK_REVAMPED_TOOL=''
NETWORK_REVAMPED_JOB=''
NETWORK_REVAMPED_KEYS=''
NETWORK_REVAMPED_SKIPPED=''
NETWORK_REVAMPED_PLAN=''
NETWORK_REVAMPED_NOW=0
NETWORK_REVAMPED_MS=0
NETWORK_REVAMPED_LIMIT=2
NETWORK_REVAMPED_NUMBER=0
NETWORK_REVAMPED_DOUBLED=''
NETWORK_REVAMPED_WANT=''
NETWORK_REVAMPED_IFACE=''
NETWORK_REVAMPED_RX=''
NETWORK_REVAMPED_TX=''
NETWORK_REVAMPED_RATE=0
NETWORK_REVAMPED_SMOOTH=0
NETWORK_REVAMPED_PLACES=1
NETWORK_REVAMPED_READ=''
NETWORK_REVAMPED_AIRPORT=''
NETWORK_REVAMPED_AIRPORT_READ=0
NETWORK_REVAMPED_STORED=0
NETWORK_REVAMPED_TIER='low'
NETWORK_REVAMPED_OUT=''
NETWORK_REVAMPED_LABEL=''
NETWORK_REVAMPED_WIDTH=''
NETWORK_REVAMPED_GLYPH=''
NETWORK_REVAMPED_NATURAL=0
NETWORK_REVAMPED_CARD=''
REVAMPED_CACHE_PREFIX=net_revamped
REVAMPED_LOG_NS=network-revamped
NETWORK_REVAMPED_KINDS='interval	number
vpn_interval	number
vpn_name_interval	number
ip_interval	number
connections_interval	number
wifi_interval	number
ssid_interval	number
online_interval	number
ping_interval	number
public_ip_interval	number
download_width	number
upload_width	number
speed_width	number
vpn_width	number
vpn_name_width	number
ip_width	number
wifi_width	number
ssid_width	number
connections_width	number
ping_width	number
public_ip_width	number
online_width	number
medium_thresh	number
high_thresh	number
precision	0 1 2 3 4 5 6 7 8 9
smoothing	number 0 99
render	jobs options
icons	ascii nerd
fixed_width	on off
ping_enabled	1 0
public_ip_enabled	1 0
online_enabled	1 0'
