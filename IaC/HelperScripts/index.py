import boto3
import json
import os
import logging

# Initialize AWS services
rekognition = boto3.client('rekognition')
sns = boto3.client('sns')

# Get the SNS topic ARN from environment variables
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    try:
        # Extract bucket and key from the S3 event
        bucket = event['Records'][0]['s3']['bucket']['name']
        key = event['Records'][0]['s3']['object']['key']
        
        # Log the S3 event details
        logger.info(f"Processing file: {key} from bucket: {bucket}")

        # Call Rekognition to search for faces in the uploaded image
        response = rekognition.search_faces_by_image(
            CollectionId='my-known-faces',  # Your Rekognition collection ID
            Image={'S3Object': {'Bucket': bucket, 'Name': key}},
            FaceMatchThreshold=90  # Minimum confidence threshold (90%)
        )

        if response['FaceMatches']:
            for match in response['FaceMatches']:
                confidence = match['Face']['Confidence']
                if confidence >= 90:  # Only trigger notifications for 90% or higher confidence
                    name = match['Face']['ExternalImageId']
                    message = f"Face detected: {name} with {confidence:.2f}% confidence in image {key}."

                    # Publish the message to the SNS topic
                    sns.publish(
                        TopicArn=SNS_TOPIC_ARN,
                        Message=message,
                        Subject="High Confidence Face Detection"
                    )

                    logger.info(f"Notification sent: {message}")
                    break  # Send notification on first match with confidence >= 90%
                else:
                    logger.info(f"Face detected but confidence is below 90%: {confidence:.2f}%")
        else:
            logger.info(f"No face match detected for image {key}.")

    except Exception as e:
        logger.error(f"Error processing image {key}: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps('Error occurred during face detection.')
        }

    return {
        'statusCode': 200,
        'body': json.dumps('Face detection and SNS notification completed successfully.')
    }
