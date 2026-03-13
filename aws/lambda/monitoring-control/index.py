"""Lambda function to start/stop/status the monitoring stack ECS service."""
import json
import os
import boto3

ecs = boto3.client('ecs')
CLUSTER = os.environ['CLUSTER_NAME']
SERVICE = os.environ['SERVICE_NAME']


def handler(event, context):
    """Handle start/stop/status actions."""
    if 'body' in event:
        body = json.loads(event['body']) if isinstance(event['body'], str) else event['body']
    else:
        body = event

    action = body.get('action', 'status')

    if action == 'start':
        ecs.update_service(cluster=CLUSTER, service=SERVICE, desiredCount=1)
        return response(200, {'message': 'Monitoring stack starting...', 'desiredCount': 1})

    elif action == 'stop':
        ecs.update_service(cluster=CLUSTER, service=SERVICE, desiredCount=0)
        return response(200, {'message': 'Monitoring stack stopping...', 'desiredCount': 0})

    elif action == 'status':
        svc = ecs.describe_services(cluster=CLUSTER, services=[SERVICE])['services'][0]
        return response(200, {
            'status': svc['status'],
            'desiredCount': svc['desiredCount'],
            'runningCount': svc['runningCount'],
            'pendingCount': svc['pendingCount'],
        })

    else:
        return response(400, {'error': f'Unknown action: {action}'})


def response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': {'Content-Type': 'application/json'},
        'body': json.dumps(body),
    }
