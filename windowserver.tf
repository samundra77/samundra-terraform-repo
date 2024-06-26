provider "aws" {
  region = "us-east-2"
}
 
resource "aws_security_group" "rdptest" {
  name        = "rdptest"
  description = "Allow RDP traffic"
 
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
 
resource "aws_instance" "windows_server" {
  ami           = "ami-08b66c1b6d6a8a30a" 
  instance_type = "t2.micro"
  key_name       = "samundrakeypair"
  vpc_security_group_ids = [aws_security_group.rdptest.id]

 
  user_data = <<-EOF
<powershell>
    # Install Chocolatey
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
 
    # Install Git using Chocolatey
    choco install git -y
 
    # Install .NET SDK using Chocolatey
    choco install dotnetcore-sdk -yterr 
 
    # Clone the repository
    cd C:\
    git clone https://github.com/samundra77/samundra-terraform-repo.git
 
    # Install IIS
    Add-WindowsFeature -Name Web-Server -IncludeManagementTools
 
    # Download and Install .NET Hosting Bundle
    $latestBundleUrl = (Invoke-WebRequest -Uri "https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/iis/hosting-bundle?view=aspnetcore-8.0").Links | Where-Object { $_.href -match "https://download.*?\.exe" } | Select-Object -First 1 -ExpandProperty href
    $bundlePath = "C:\\test-winserver\\dotnet-hosting.exe"
    Invoke-WebRequest -Uri $latestBundleUrl -OutFile $bundlePath
    Start-Process -FilePath $bundlePath -ArgumentList '/quiet' -Wait
</powershell>
  EOF
 
  tags = {
    Name = "samundra-winserver"
  }
}
 
resource "aws_cloudwatch_metric_alarm" "high_cpu_utilization" {
  alarm_name          = "high_cpu_utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "70"
 
  dimensions = {
    InstanceId = aws_instance.windows_server.id
  }
 
  alarm_actions = [
    "arn:aws:sns:us-east-2:123456789012:my_sns_topic" 
  ]
}
 
resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "low_cpu_utilization"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "20"
 
  dimensions = {
    InstanceId = aws_instance.windows_server.id
  }
 
  alarm_actions = [
    "arn:aws:sns:us-east-2:123456789012:my_sns_topic"
  ]
}
