# Sample External URL
This is a sample application in **Python** which is collecting external **URL** metrics and producing Prometheus format metrics at the endpoint **/metrics**. Prometheus is collecting the metrics from the endpoint and a dashboard in Grafana is used to display the metrics.

The following **URLS** are being used as demo:-
1. [https://httpstat.us/200](https://httpstat.us/200)
2. [https://httpstat.us/503](https://httpstat.us/503)

The metrics currently being collected are:-
1. **URL response time in milliseconds**
2. **URL status up or down using 1 or 0 respectively**

There is also **Dockerfile** which is converting the **Python** application into a container based application and then the application is being deployed to **K8s** cluster.

## Using The Application For Development
**Python3.9 is required**

0. Clone git repository and enter into the folder
```
git clone https://github.com/ktchethan/testservice.git
cd sample_external_url
```

1. Create and activate a virtual environment

`Linux`

```
python -m venv venv
source venv/bin/activate
```

`Windows`

```
python -m venv venv
.\venv\Scripts\activate.bat
```

2. Install the required packages inside the environment

```
pip install -r src/requirements-dev.txt
```

3. Run unit-test of the application using **pytest**

```
pytest
```

4. Export environment variables for the application

`Linux`

```
export URLS='https://httpstat.us/503','https://httpstat.us/200'
export TIMEOUT=2
export PORT=8080
```

`Windows`

[https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/set_1](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/set_1)

5. Run the application

```
python src/app.py
```

6. Check the application
Open your browser and point to [http://localhost or VM_IP:8080](http://localhost or VM_IP:8080) you will see a text message.
To see the metrics point your browser to [http://localhost or VM_IP:8080/metrics](http://localhost or VM_IP:8080/metrics)

7. Exit the application
```
Ctrl + c
```
"Bringing Down Service ".

## Building The Container Image For Production
**Docker is required**

1. Build the Docker image

```
docker build -t sample_external_url .
```

2. Check the application if the container is working perfectly

```
docker run -d -p 8080:8080 --env-file ./env-file --name sample sample_external_url
```
Open your browser and point to [http://localhost or VM_IP:8080](http://localhost or VM_IP:8080) you will see a text message.
To see the metrics point your browser to [http://localhost or VM_IP:8080/metrics](http://localhost or VM_IP:8080/metrics)

3. Create new repository on **DockerHub** or your preferred docker registry.

4. Login to your docker registry in console

```
docker login
```

5. Push the image to **DockerHub** or to your preferred docker registry

```
docker tag sample_external_url:latest [USERNAME]/sample_external_url:latest
docker push [USERNAME]/sample_external_url:latest
```

## Deploy The Application Container Image On K8s Cluster

The folder **k8s** contains the **sample_external_url.yaml** file which contains the code for **Kubernetes** deployment.

The file contains following segments:-

1. **CongfigMap** - This contains all the configuration of the application that is the environment variables.

2. **Deployment** - This contains the **k8s** deployment of the application. The **POD** refers to the **configmap** for the configuration. Image used for the **POD** is **image: testhubk8s/myservice:testservice.1.0**, change that according to your registry url.

**Note:-** DockerHub URL [https://hub.docker.com/repository/docker/testhubk8s/myservice](https://hub.docker.com/repository/docker/testhubk8s/myservice)

3. **Service** - This will expose the application as **ClusterIP** on **port 80** and **targetPort 8080**. Change the **targetPort** value according to the **PORT** value in **configmap**.

### Deploy The Application

1. Create a namespace

```
kubectl create ns sample-external-url
```

2. Deploy application in the above created namespace

```
kubectl apply -f k8s/sample_external_url.yaml -n sample-external-url
```

3. Display all the components deployed

```
kubectl get all -n sample-external-url
```
![kubectl-get-all](https://user-images.githubusercontent.com/19147273/130400037-3fdd578f-2cd3-4367-83b1-a760f62d2668.PNG)

4. Display all the services deployed

```
kubectl get svc -n sample-external-url
```
![kubectl-get-svc](https://user-images.githubusercontent.com/19147273/130400858-eafd9c28-e34d-4aab-bb4f-416d56888593.PNG)


**Note:-** Write down the **CLUSTER-IP** we would need it later.

5. Check the application

```
kubectl port-forward service/sample-external-url-service 8080:80 -n sample-external-url
```
Open your browser and point to [http://localhost or VM_IP:8080](http://localhost or VM_IP:8080) you will see a text message.
To see the metrics point your browser to [http://localhost or VM_IP:8080/metrics](http://localhost or VM_IP:8080/metrics)

## Deploy Prometheus

1. Get Repo Info

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add kube-state-metrics https://kubernetes.github.io/kube-state-metrics
helm repo update
```

2. Install Chart

```
helm install prometheus prometheus-community/prometheus
```

**Note:-** [https://artifacthub.io/packages/helm/prometheus-community/prometheus](https://artifacthub.io/packages/helm/prometheus-community/prometheus)

## Deploy Grafana

1. Get Repo Info

```
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

2. Install Chart

```
helm install grafana grafana/grafana
```

**Note:-** [https://github.com/grafana/helm-charts/tree/main/charts/grafana](https://github.com/grafana/helm-charts/tree/main/charts/grafana)

3. Get the login username and password

```
kubectl get secrets grafana -o jsonpath='{.data.admin-password}' | base64 --decode | cut -d "%" -f1
kubectl get secrets grafana -o jsonpath='{.data.admin-user}' | base64 --decode | cut -d "%" -f1
```

## Update Prometheus Config To Scrape Metrics From The Application

1. Update configmap for Prometheus

```
kubectl edit cm/prometheus-server
```
![prometheus-config](https://user-images.githubusercontent.com/19147273/130400226-063174f1-d70a-4aad-8144-0ff132477f0a.PNG)

2. Add the following config under **scrape_configs**

```
- job_name: 'sample_external'
      static_configs:
      - targets: ['CLUSTER-IP:80']
```
![image](https://user-images.githubusercontent.com/19147273/130400301-a15331e1-89d7-42b1-81eb-bf3e25dd96da.png)

**Note:-** Replace **CLUSTER-IP** with the ip that we noted down earlier. In my case it will be **10.254.42.142**.

## Port Forward Prometheus And Grafana

1. Port forward Prometheus

```
kubectl port-forward service/prometheus-server 9090:80
```

2. Port forward Grafana

```
kubectl port-forward service/grafana 3000:80
```

3. Open Prometheus

Open your browser and point to [http://localhost:9090](http://localhost:9090) you will see **Prometheus UI**.

4. Check Prometheus config

Open your browser and point to [http://localhost:9090](http://localhost:9090) you will see **Prometheus UI**. Go to **Status** > **Configuration** and you can see that your configuration has been added under **scrape_configs:**.

![prometheus-config](https://user-images.githubusercontent.com/19147273/130400385-8d66ee10-2f43-4420-90b7-770616177ffc.PNG)



5. Check **Prometheus** metrics collected from our **Application**


6. Open Grafana

Open your browser and point to [http://localhost:3000](http://localhost:3000) you will see **Grafana Login**.

Enter the **username** and **password** we already collected to login.

## Add Prometheus Data Source To Grafana

1. Open Grafana

Open your browser and point to [http://localhost:3000](http://localhost:3000) you will see **Grafana Login**.

Enter the **username** and **password** we already collected to login.

2. Click on **Configuration** > **Data Sources**

3. Click on **Add data source**

![grafan-configuration](https://user-images.githubusercontent.com/19147273/130400582-a297302b-e6e1-425c-a2f0-d4a32b6bfbf5.png)



4. Select **Prometheus** as the data source

![grafan-configuration-add-data-source](https://user-images.githubusercontent.com/19147273/130400614-f46ee497-e468-470e-aabf-d636be040ed0.png)


5. Check Prometheus cluster ip

```
kubectl get svc
```
![Prometheus Server](https://user-images.githubusercontent.com/19147273/130401811-2e576b5d-9ae7-475a-843a-ff824a73e424.png)


**Note:-** Write down the **ClusterIP** for **prometheus-server**


6. Add the **ClusterIP** as the **Prometheus** url



7. Click **Save & Test**


## Import Grafana Dashboard

1. Click on **Create** > **Import**

2. Click on **Upload JSON file** and select the file from the **grafana** folder within this repository.

   ![image](https://user-images.githubusercontent.com/19147273/130402045-7ea205f8-c834-439e-a0df-e113fc5fa6dc.png)



3. Click on **Import** button it will create the dashboard with the **Prometheus** metrics.
   "Browse Json file @ grafana\sample External URL Test.json or copy the content of json and upload"


