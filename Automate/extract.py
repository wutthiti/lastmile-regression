import xml.etree.ElementTree as ET
import base64
import re
import os

xml_file = r"c:\ShareFolder\BJC\DriverApp\Automate\output.xml"
artifact_dir = r"C:\Users\thiti\.gemini\antigravity-ide\brain\c55a978e-5844-488c-9318-b6cb9d066a71"
output_png = os.path.join(artifact_dir, "screenshot.png")

with open(xml_file, 'r', encoding='utf-8') as f:
    content = f.read()

match = re.search(r'src="data:image/png;base64,([^"]+)"', content)
if match:
    b64_data = match.group(1)
    with open(output_png, "wb") as f:
        f.write(base64.b64decode(b64_data))
    print("Screenshot saved to", output_png)
else:
    print("No base64 screenshot found")
