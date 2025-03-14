prereqs: desktop/.venv raspberrypi/.venv

desktop/.venv:
	cd desktop && uv venv .venv && \
	. .venv/bin/activate && uv pip install -r requirements.txt

raspberrypi/.venv:
	cd raspberrypi && uv venv .venv && \
	. .venv/bin/activate && uv pip install -r requirements.txt
	
test:
	pm2 start ecosystem.config.js

stop:
	pm2 stop all && pm2 delete all

clean:
	rm -rf *log