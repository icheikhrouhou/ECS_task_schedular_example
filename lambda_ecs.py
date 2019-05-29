import boto3
import os
  
def lambda_handler(event, context):
		
  ecs = boto3.client('ecs')
	response = ecs.run_task(
        cluster='cluster_name',
        taskDefinition='batch',
        launchType='EC2',
        tags=[
        {
            'key': 'ENV',
            'value': 'dev'
        },
        ],
        overrides={
            'containerOverrides': [
                {
                    'name': 'batch',
                    'command': [
                        '/tmp/batch_script.sh',
                    ],
                    'cpu': 123,
                    'memory': 123,
                    'memoryReservation': 123,
                    'taskRoleArn': '',  
                        'environment': [
                            {
                                'name': 'ENV',
                                'value': dev
                            },
                        ]
                    },
                ]
            },
        count=1
	)

  arn = response["tasks"][0]['taskArn']
  waiter = ecs.get_waiter('tasks_stopped')
  waiter.wait(cluster='cluster_name', tasks=[arn])
  return "response={}".format(response)
		
	
