from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime
import requests

API_URL = "{{ api_url }}"
DB_NAME = "{{ db_name }}"

def print_config():
    print(f"API URL: {API_URL}")
    print(f"Database: {DB_NAME}")

with DAG(
    dag_id="sample_multi_env_dag",
    start_date=datetime(2024, 1, 1),
    schedule_interval="@daily",
    catchup=False,
) as dag:

    task = PythonOperator(
        task_id="print_env_config",
        python_callable=print_config,
    )
