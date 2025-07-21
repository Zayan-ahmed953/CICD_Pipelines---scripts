import os
import boto3
import tempfile
import mimetypes
from PIL import Image
import subprocess
import shutil

s3 = boto3.client('s3')
DEST_BUCKET = 'destination-bucket-5326'

def lambda_handler(event, context):
    for record in event['Records']:
        src_bucket = record['s3']['bucket']['name']
        src_key = record['s3']['object']['key']

        file_name = os.path.basename(src_key)
        file_ext = os.path.splitext(file_name)[-1].lower()

        with tempfile.TemporaryDirectory() as tmpdir:
            download_path = os.path.join(tmpdir, file_name)
            upload_path = os.path.join(tmpdir, f"compressed_{file_name}")

            # Download the file
            s3.download_file(src_bucket, src_key, download_path)

            # Guess MIME type
            mime_type, _ = mimetypes.guess_type(download_path)
            print(f"Processing file: {file_name}, MIME type: {mime_type}")

            # Handle images
            if file_ext in ['.jpg', '.jpeg', '.png']:
                compress_image(download_path, upload_path)

            # Handle videos
            elif file_ext in ['.mp4', '.avi', '.mkv']:
                compress_video(download_path, upload_path)

            # Handle audio
            elif file_ext in ['.mp3']:
                compress_audio(download_path, upload_path)

            # Handle documents - copy as-is
            elif file_ext in ['.doc', '.docx', '.xls', '.xlsx']:
                print(f"Copying document file without compression: {file_name}")
                shutil.copy(download_path, upload_path)

            else:
                print(f"Unsupported file type: {file_name}")
                continue

            # Preserve folder structure
            dest_key = src_key
            s3.upload_file(upload_path, DEST_BUCKET, dest_key)
            print(f"Processed file uploaded to: s3://{DEST_BUCKET}/{dest_key}")

def compress_image(input_path, output_path):
    try:
        with Image.open(input_path) as img:
            img_format = img.format.upper()
            if img_format == 'JPEG':
                img.save(output_path, format='JPEG', optimize=True, quality=70)
            elif img_format == 'PNG':
                img.save(output_path, format='PNG', optimize=True)
            else:
                shutil.copy(input_path, output_path)
    except Exception as e:
        print(f"Image compression error: {e}")
        raise

def compress_video(input_path, output_path):
    try:
        cmd = [
            '/opt/bin/ffmpeg',
            '-i', input_path,
            '-c:v', 'libx264',
            '-preset', 'faster',
            '-crf', '23',
            '-c:a', 'aac',
            '-b:a', '128k',
            output_path
        ]
        subprocess.run(cmd, check=True)
    except Exception as e:
        print(f"Video compression error: {e}")
        raise

def compress_audio(input_path, output_path):
    try:
        cmd = [
            '/opt/bin/ffmpeg',
            '-i', input_path,
            '-codec:a', 'libmp3lame',
            '-qscale:a', '4',
            output_path
        ]
        subprocess.run(cmd, check=True)
    except Exception as e:
        print(f"Audio compression error: {e}")
        raise
