"""Build a self-contained HTML study from project documentation and evidence."""
from pathlib import Path
import base64,csv,re,html,json
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1];D=R/'deliverables';D.mkdir(exist_ok=True);E=R/'evidence'
rows=list(csv.DictReader((E/'arcade-act1-jump.csv').open()));x=[int(r['relative_frame']) for r in rows];h=[int(r['height_pixels']) for r in rows]
s=(R/'src/lion-arcade-tables.inc').read_text().split('lion_jump:')[1].split('lion_pots_lo:')[0]
native=list(map(int,re.findall(r'\d+',s.replace('.byte',''))));assert native==h
plt.rcParams.update({'font.size':11,'axes.spines.top':False,'axes.spines.right':False})
fig,ax=plt.subplots(figsize=(9,3.4),layout='constrained');fig.patch.set_facecolor('#f7f5ee');ax.set_facecolor('#f7f5ee')
ax.plot(x,h,color='#253a44',lw=2,label='Arcade RAM observation')
ax.scatter(x[::3],native[::3],s=26,color='#d85a28',zorder=3,label='Atari table (all 64 values match)')
ax.set(xlabel='Simulation frame after takeoff',ylabel='Displayed height (pixels)',xlim=(0,63),ylim=(0,61));ax.grid(alpha=.15);ax.legend(frameon=False,loc='upper right');fig.savefig(E/'reference-images/jump-comparison.png',dpi=150);plt.close(fig)
def data(path):return 'data:image/png;base64,'+base64.b64encode(path.read_bytes()).decode()
# Exact native screenshots, assembled without retouching pixels.
shots=[('Through the fire hoop','atari-through-hoop.png'),('Close double hoops','atari-double.png'),('Approaching the platform','atari-goal.png')]
out=Image.new('RGB',(1008,270),'#172e35');draw=ImageDraw.Draw(out)
try:font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',16)
except OSError:font=ImageFont.load_default()
for i,(label,name) in enumerate(shots):
 draw.text((i*336+10,12),label,fill='#f7f5ee',font=font);im=Image.open(E/'reference-images'/name).convert('RGB');out.paste(im,(i*336,40))
out.save(D/'Circus-Charlie-Act1-Preview.png')
# Diagram uses explicit SVG geometry, so the saved report works offline.
parts=['<svg viewBox="0 0 760 810" role="img" aria-label="Act 1 active-frame control flow" xmlns="http://www.w3.org/2000/svg"><defs><marker id="arrow" markerWidth="8" markerHeight="8" refX="7" refY="4" orient="auto"><path d="M0 0L8 4L0 8" fill="#657c7e"/></marker></defs>']
def arrow(d,label=None,x=0,y=0):
 parts.append(f'<path d="{d}" fill="none" stroke="#657c7e" stroke-width="2" marker-end="url(#arrow)"/>')
 if label:parts.append(f'<text x="{x}" y="{y}" fill="#385458" font-size="13">{html.escape(label)}</text>')
def box(x,y,w,h,lines,tone='#e5eee6'):
 parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="12" fill="{tone}" stroke="#b2c2b7"/>')
 for i,line in enumerate(lines):parts.append(f'<text x="{x+w/2}" y="{y+h/2+(i-(len(lines)-1)/2)*20+5}" text-anchor="middle" fill="#18353c" font-size="15">{html.escape(line)}</text>')
box(230,10,300,60,['Active frame · $727A']);box(230,100,300,60,['Common services and rewards'])
box(230,190,300,60,['Hoop or pot collision?'],'#f9e3c9');box(580,190,150,60,['Death / retry'],'#f5d7ce')
box(230,290,300,60,['Airborne?'],'#f9e3c9');box(35,390,290,70,['Read direction and fire','Set takeoff speed'])
box(435,390,290,70,['Integrate vertical velocity','Buffer late landing input'])
box(435,500,290,65,['Descending onto end platform?'],'#f9e3c9');box(435,610,290,60,['Clear, celebration and bonus'],'#d5e5f0')
box(35,610,310,70,['Move scenery and objects','Allocate waves; publish poses'])
arrow('M380 70V100');arrow('M380 160V190');arrow('M530 220H580','Yes',542,208);arrow('M380 250V290','No',391,275)
arrow('M230 320H180V390','No',195,310);arrow('M530 320H580V390','Yes',540,310);arrow('M180 460V610')
arrow('M580 460V500');arrow('M580 565V610','Yes',590,590);arrow('M435 532H375V645H345','No',385,520)
arrow('M190 680V750H15V40H230','Next frame',36,738)
parts.append('</svg>');svg=''.join(parts);(E/'reference-images/act1-flowchart.svg').write_text(svg)
def inline(s):
 s=html.escape(s)
 s=re.sub(r'`([^`]+)`',r'<code>\1</code>',s)
 s=re.sub(r'\*\*([^*]+)\*\*',r'<strong>\1</strong>',s)
 s=re.sub(r'\[([^\]]+)\]\((https?://[^)]+)\)',r'<a href="\2">\1</a>',s)
 return s
lines=(R/'docs/ACT1-ARCADE.md').read_text().splitlines();body=[];i=0
while i<len(lines):
 line=lines[i]
 if not line.strip():i+=1;continue
 if line.startswith('```mermaid'):
  while i<len(lines) and not (i>0 and lines[i]=='```'):i+=1
  body.append('<div class="diagram">'+svg+'</div>');i+=1;continue
 if line.startswith('|'):
  table=[]
  while i<len(lines) and lines[i].startswith('|'):
   table.append([c.strip() for c in lines[i].strip('|').split('|')]);i+=1
  body.append('<div class="table"><table><thead><tr>'+''.join('<th>'+inline(c)+'</th>' for c in table[0])+'</tr></thead><tbody>')
  for row in table[2:]:body.append('<tr>'+''.join('<td>'+inline(c)+'</td>' for c in row)+'</tr>')
  body.append('</tbody></table></div>');continue
 if line.startswith('#'):
  level=len(line)-len(line.lstrip('#'));body.append(f'<h{level}>'+inline(line[level:].strip())+f'</h{level}>');i+=1;continue
 if line.startswith('- '):
  body.append('<ul>')
  while i<len(lines) and lines[i].startswith('- '):body.append('<li>'+inline(lines[i][2:])+'</li>');i+=1
  body.append('</ul>');continue
 para=[line];i+=1
 while i<len(lines) and lines[i].strip() and not lines[i].startswith(('#','|','- ','```')):para.append(lines[i]);i+=1
 body.append('<p>'+inline(' '.join(para))+'</p>')
comparison='<section><h2>Native pictures from both executables</h2><p>Arcade frames come from the normal joystick/fire run. Atari frames come from the delivered cartridge. Their display shapes differ; images are not stretched to conceal that difference.</p>'
for label,orig,new in [('Money hoop and hanger',1080,'atari-money.png'),('Close pair',1620,'atari-double.png'),('Landing platform',2370,'atari-goal.png')]:
 comparison+=f'<h3>{label}</h3><div class="comparison"><figure><img src="{data(E/f"reference-images/arcade-{orig}.png")}" alt="Arcade {label}"><figcaption>Original arcade · MAME</figcaption></figure><figure><img src="{data(E/f"reference-images/{new}")}" alt="Atari {label}"><figcaption>Atari revision · native capture</figcaption></figure></div>'
comparison+='</section><section><h2>The measured jump</h2><img class="chart" src="'+data(E/'reference-images/jump-comparison.png')+'" alt="Arcade and Atari jump heights agree at all 64 samples"></section>'
css='''*{box-sizing:border-box}body{margin:0;background:#f7f5ee;color:#253a44;font:16px/1.65 system-ui,sans-serif}header{background:#172e35;color:#f7f5ee;padding:48px max(6vw,24px)}header .eyebrow{color:#f4b75e;letter-spacing:.18em;font-size:12px}header h1{font-size:clamp(28px,5vw,52px);margin:.3em 0;line-height:1.1}header p{max-width:780px;color:#c5d8d3}.metrics{display:flex;gap:45px;flex-wrap:wrap;margin-top:32px}.metrics b{display:block;color:#f4b75e;font-size:34px}.metrics span{font-size:13px}main{max-width:1080px;margin:auto;padding:36px 24px 70px}h1{font-size:30px}h2{margin-top:2.4em;font-size:25px;border-top:1px solid #cbd3cb;padding-top:22px}h3{font-size:19px}a{color:#226e82}code{font:13px/1.5 ui-monospace,monospace;background:#e9ece4;padding:2px 5px;border-radius:3px;overflow-wrap:anywhere}.table{overflow:auto}table{border-collapse:collapse;width:100%;font-size:14px;line-height:1.55;margin:18px 0}th{text-align:left;background:#203b43;color:white;padding:12px}td{padding:12px;vertical-align:top;border-bottom:1px solid #d7ddd3}tr:nth-child(even){background:#edf0e8}.comparison{display:grid;grid-template-columns:1fr 1.5fr;gap:24px;background:#172e35;padding:24px;border-radius:12px}figure{margin:0;text-align:center}figure img{height:280px;max-width:100%;object-fit:contain;image-rendering:pixelated}figcaption{color:#c5d8d3;font-size:12px;margin-top:10px}.chart{width:100%}.diagram{max-width:760px;margin:20px auto}.diagram svg{width:100%;height:auto}footer{font-size:12px;color:#647d7a;border-top:1px solid #cbd3cb;padding-top:20px}@media(max-width:650px){.comparison{grid-template-columns:1fr}figure img{height:auto;width:100%}.metrics{gap:24px}td,th{min-width:140px}}@media print{header{padding:20px}.comparison{break-inside:avoid}body{font-size:11px}.diagram{max-width:600px}h2{break-after:avoid}}'''
page='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Circus Charlie — Act 1 arcade study</title><style>'+css+'</style><header><div class="eyebrow">CIRCUS CHARLIE · ATARI 800XL · REVISION 8</div><h1>Act 1, measured from the arcade</h1><p>Direct executable analysis, native emulator observations and the resulting Atari revision. Includes the changes that are matched and the arcade details that still differ.</p><div class="metrics"><span><b>20.3 s</b>Normal Atari replay</span><span><b>14 frames</b>Arcade close-pair release</span><span><b>64 / 64</b>Jump samples matched</span><span><b>0</b>Act 1 deadline misses, PAL &amp; NTSC</span></div></header><main>'+comparison+''.join(body)+'<footer>Generated from the supplied executable observations and this source checkpoint. Original game and graphic designs: Konami. Independent Atari implementation. Cartridge SHA-256: '+json.loads((E/'release.json').read_text())['car_sha256']+'</footer></main></html>'
(D/'Circus-Charlie-Act1-Study.html').write_text(page)
print(D/'Circus-Charlie-Act1-Study.html')
