# Define a local DNS Entry

Connect to Primary DNS Server using Webmin
e.g. https://ns01.ozlan.org:10000/

- Click Servers > Bind DNS Server
- Select zone 'ozlan.org'
- Click 'Address'

Specify Entry details
- Name: jenkins02
- Address: 192.168.4.50
- Ensure: Update reverse ticked
- Click Create
- Click return to zone list
- Stop and Start bind service to apply changes

Test the new Hostname
e.g.
http://jenkins02.ozlan.org:8080/
