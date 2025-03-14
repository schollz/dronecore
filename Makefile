prereqs: desktop/.venv raspberrypi/.venv orchestator/orchestator

desktop/.venv:
	cd desktop && uv venv .venv && \
	. .venv/bin/activate && uv pip install -r requirements.txt

raspberrypi/.venv:
	cd raspberrypi && uv venv .venv && \
	. .venv/bin/activate && uv pip install -r requirements.txt
	
orchestator/orchestator:
	cd orchestator && go build -v 

test:
	pm2 start ecosystem.config.js

stop:
	pm2 stop all && pm2 delete all

clean:
	rm -rf *log