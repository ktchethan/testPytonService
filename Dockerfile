FROM python:3.9-alpine

WORKDIR /app

COPY src/ .

RUN pip install -r req.txt

CMD ["python", "testservice.py"]
