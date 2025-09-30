# AWS Central-Spoke Architecture with Load Balancers and Proxy

이 프로젝트는 AWS에서 Central-Spoke 아키텍처를 구현하여 중앙 집중식 네트워크 관리와 보안 처리를 제공합니다.

## 🏗️ 아키텍처 다이어그램

```
┌────────────────────────────────────────────────────────────────────────────────┐
│                                INTERNET                                        │
└──────────────────────────────┬─────────────────────────────────────────────────┘
                               │
┌──────────────────────────────┼─────────────────────────────────────────────────┐
│                              │           Central VPC (10.0.0.0/16)             │
│  ┌───────────────────────────┼───────────── ────────────────────────────────┐  │
│  │                           │                                              │  │
│  │   ┌───────────────────────┼──────────────────────────────────────────┐   │  │
│  │   │            Internet Gateway (IGW)                                │   │  │
│  │   └───────────────────────┼──────────────────────────────────────────┘   │  │
│  │                           │                                              │  │
│  │  ┌────────────────────────┼──────────────────────────────────────────┐   │  │
│  │  │              Public Subnets                                       │   │  │
│  │  │   ┌──────────────────┐ │ ┌──────────────────┐                     │   │  │
│  │  │   │  ap-northeast-2a │ │ │  ap-northeast-2c │                     │   │  │
│  │  │   │   10.0.0.0/24    │ │ │   10.0.1.0/24    │                     │   │  │
│  │  │   └──────────────────┘ │ └──────────────────┘                     │   │  │
│  │  │              │         │         │                                │   │  │
│  │  │              │    Internet-facing ALB                             │   │  │
│  │  │              │         │         │                                │   │  │
│  │  │   ┌──────────────────┐ │ ┌──────────────────┐                     │   │  │
│  │  │   │   NAT Gateway    │ │ │   NAT Gateway    │                     │   │  │
│  │  │   │     (AZ-a)       │ │ │     (AZ-c)       │                     │   │  │
│  │  │   └──────────────────┘ │ └──────────────────┘                     │   │  │
│  │  └────────────────────────┼──────────────────────────────────────────┘   │  │
│  │                           │                                              │  │
│  │  ┌────────────────────────┼──────────────────────────────────────────┐   │  │
│  │  │             Private Subnets                                       │   │  │
│  │  │   ┌──────────────────┐ │ ┌──────────────────┐                     │   │  │
│  │  │   │  ap-northeast-2a │ │ │  ap-northeast-2c │                     │   │  │
│  │  │   │  10.0.10.0/24    │ │ │  10.0.11.0/24    │                     │   │  │
│  │  │   └──────────────────┘ │ └──────────────────┘                     │   │  │
│  │  │              │         │         │                                │   │  │
│  │  │              │    Internal NLB                                    │   │  │
│  │  │              │         │         │                                │   │  │
│  │  │   ┌──────────────────┐ │ ┌──────────────────┐                     │   │  │
│  │  │   │  Nginx Proxy     │ │ │  Nginx Proxy     │                     │   │  │
│  │  │   │   (Port 8080)    │ │ │   (Port 8080)    │                     │   │  │
│  │  │   └──────────────────┘ │ └──────────────────┘                     │   │  │
│  │  └────────────────────────┼──────────────────────────────────────────┘   │  │
│  └───────────────────────────┼──────────────────────────────────────────────┘  │
└──────────────────────────────┼─────────────────────────────────────────────────┘
                               │
┌──────────────────────────────┼──────────────────────────────────────────────────┐
│                              │                                                  │
│               Transit Gateway (Hub-Spoke Router)                                │
│                              │                                                  │
└──────────────────────────────┼──────────────────────────────────────────────────┘
                               │
┌──────────────────────────────┼──────────────────────────────────────────────────┐
│                              │           Spoke VPC (10.1.0.0/16)                │
│  ┌───────────────────────────┼───────────────────────────────────────────────┐  │
│  │                           │                                               │  │
│  │  ┌────────────────────────┼───────────────────────────────────────────┐   │  │
│  │  │              Subnets (No Internet Gateway)                         │   │  │
│  │  │   ┌──────────────────┐ │ ┌──────────────────┐                      │   │  │
│  │  │   │  Main Subnet     │ │ │ Private Subnet   │                      │   │  │
│  │  │   │ ap-northeast-2a  │ │ │ ap-northeast-2c  │                      │   │  │
│  │  │   │  10.1.1.0/24     │ │ │ 10.1.10.0/24     │                      │   │  │
│  │  │   └──────────────────┘ │ └──────────────────┘                      │   │  │
│  │  │                        │         │                                 │   │  │
│  │  │                        │   Python HTTP                             │   │  │
│  │  │                        │    Web Server                             │   │  │
│  │  │                        │   (Port 80)                               │   │  │
│  │  └────────────────────────┼───────────────────────────────────────────┘   │  │
│  └───────────────────────────┼───────────────────────────────────────────────┘  │
└──────────────────────────────┼──────────────────────────────────────────────────┘
```

## 📊 네트워크 플로우 상세 다이어그램

```
🌐 External Client
    ↓ HTTP/HTTPS Request
┌─────────────────────────────────────────────────────────────────┐
│  Internet Gateway (Central VPC)                                 │
└─────────────────────────────────────────────────────────────────┘
    ↓ Route to ALB
┌─────────────────────────────────────────────────────────────────┐
│ Internet-facing ALB (Public Subnets)                            │
│    • Health Check: /health                                      │
│    • Ports: 80, 443                                             │
│    • Target: Internal NLB IPs                                   │
└─────────────────────────────────────────────────────────────────┘
    ↓ Forward to NLB IPs
┌─────────────────────────────────────────────────────────────────┐
│ Internal NLB (Private Subnets)                                  │
│    • Health Check: HTTP 8080 /health                            │
│    • Target: Proxy Instances                                    │
└─────────────────────────────────────────────────────────────────┘
    ↓ Load Balance to Proxies
┌─────────────────────────────────────────────────────────────────┐
│   Nginx Proxy Instances(2개 Multi-AZ)                           │
│    • Listen: Port 8080                                          │
│    • Upstream: Spoke Web Server                                 │
│    • Security Layer & Request Filtering                         │
└─────────────────────────────────────────────────────────────────┘
    ↓ Proxy Pass via TGW
┌─────────────────────────────────────────────────────────────────┐
│    Transit Gateway                                              │
│    • Central ↔ Spoke VPC Routing                                │
│    • Route: 10.1.0.0/16 → Spoke VPC                             │
│    • Route: 0.0.0.0/0 → Central VPC (from Spoke)                │
└─────────────────────────────────────────────────────────────────┘
    ↓ Route to Spoke VPC
┌─────────────────────────────────────────────────────────────────┐
│    Python HTTP Web Server (Spoke VPC)                           │
│    • Listen: Port 80                                            │
│    • Response: HTML with Instance Metadata                      │
│    • Location: Private Subnet (10.1.10.0/24)                    │
└─────────────────────────────────────────────────────────────────┘
```

## 📋 주요 구성 요소

### 🏢 Central VPC (중앙 허브)
- **CIDR**: `10.0.0.0/16`
- **가용 영역**: `ap-northeast-2a`, `ap-northeast-2c`
- **구성 요소**:
  ```
  📍 Public Subnets:
    • 10.0.0.0/24  (AZ-a) - ALB, NAT Gateway
    • 10.0.1.0/24  (AZ-c) - ALB, NAT Gateway

  📍 Private Subnets:
    • 10.0.10.0/24 (AZ-a) - NLB, Proxy Instance
    • 10.0.11.0/24 (AZ-c) - NLB, Proxy Instance
  ```

### 🎯 Spoke VPC (워크로드)
- **CIDR**: `10.1.0.0/16`
- **특징**:
  - ❌ Internet Gateway 없음 (Central를 통해서만 인터넷 접근)
  - 🐍 Python3 HTTP 서버를 실행하는 EC2 인스턴스
  - 🚛 Transit Gateway를 통해 Central VPC와 연결
- **구성 요소**:
  ```
  📍 Subnets:
    • 10.1.1.0/24  (AZ-a) - Main Subnet
    • 10.1.10.0/24 (AZ-c) - Private Subnet (Web Server)
  ```

### 🔐 보안 구성
```
🛡️ Security Groups:
├── ALB Security Group
│   ├── Inbound: HTTP (80), HTTPS (443) from 0.0.0.0/0
│   └── Outbound: All traffic
├── Proxy Security Group
│   ├── Inbound: HTTP (8080), SSH (22) from Central VPC
│   └── Outbound: All traffic
└── Spoke Security Group
    ├── Inbound: HTTP (80), SSH (22) from Central VPC
    └── Outbound: All traffic

🔄 Network Isolation:
• Spoke VPC has NO direct internet access
• All traffic routes through Central VPC
• WAF/Security policies applied at Proxy layer
```

## 🔧 기술 스택

- **Infrastructure**: Terraform
- **Cloud Provider**: AWS (ap-northeast-2)
- **Operating System**: Amazon Linux 2023
- **Web Server**: Python3 HTTP Server
- **Proxy**: Nginx
- **Load Balancers**: ALB (Application Load Balancer), NLB (Network Load Balancer)
- **Management**: AWS Systems Manager (SSM)

## 📁 파일 구조

```
📦 AWS_ALB_NLB_WAF_TGW_NLB_EC2/
├── 📄 main.tf                 # Provider 설정 및 공통 데이터
├── 📄 variables.tf            # 변수 정의
├── 📄 hub-vpc.tf             # Central VPC 및 네트워킹 리소스
├── 📄 transit-gateway.tf     # Transit Gateway 설정
├── 📄 spoke-vpcs.tf          # Spoke VPC 정의
├── 📄 load-balancers.tf      # ALB/NLB 설정
├── 📄 proxy-instances.tf     # Nginx Proxy 인스턴스
├── 📄 spoke-instances.tf     # Spoke VPC 웹 서버
├── 📄 iam.tf                 # IAM 역할 및 SSM 설정
├── 📄 outputs.tf             # 출력 값들
├── 📄 proxy-config.tftpl     # Nginx 설정 템플릿
└── 📄 terraform.tfvars.example # 변수 예제 파일
```

## 🚀 배포 방법

### 1. 사전 준비
```bash
# AWS CLI 설정 확인
aws configure list

# Terraform 설치 확인
terraform version
```

### 2. 변수 설정
```bash
# terraform.tfvars 파일 생성
cp terraform.tfvars.example terraform.tfvars

# 필요한 변수 수정
vim terraform.tfvars
```

### 3. 배포 실행
```bash
# Terraform 초기화
terraform init

# 배포 계획 확인
terraform plan

# 배포 실행
terraform apply
```

### 4. 리소스 정리
```bash
# 모든 리소스 삭제
terraform destroy
```

## 🔧 주요 변수

| 변수명 | 기본값 | 설명 |
|--------|--------|------|
| `aws_region` | ap-northeast-2 | AWS 리전 |
| `project_name` | central-spoke | 프로젝트 이름 |
| `environment` | prod | 환경 이름 |
| `central_vpc_cidr` | 10.0.0.0/16 | Central VPC CIDR |
| `spoke_vpc_cidr` | 10.1.0.0/16 | Spoke VPC CIDR |
| `instance_type` | t3.medium | EC2 인스턴스 타입 |
| `key_name` | "" | EC2 키 페어 이름 |

## 📊 출력 값

배포 완료 후 다음 정보들이 출력됩니다:

```
🌐 Network Endpoints:
├── alb_dns_name: Internet-facing ALB DNS 이름
├── nlb_dns_name: Internal NLB DNS 이름
└── spoke_instance_ip: Spoke VPC 웹 서버 Private IP

🏗️ Infrastructure IDs:
├── central_vpc_id: Central VPC ID
├── spoke_vpc_id: Spoke VPC ID
└── transit_gateway_id: Transit Gateway ID

💻 Instance Information:
├── proxy_instance_ids: Proxy 인스턴스 ID들
└── spoke_web_instance_id: Spoke 웹 서버 인스턴스 ID
```

## 🌐 네트워크 플로우

### 📥 인바운드 트래픽
```
1. External Client
   ↓ HTTP Request
2. Internet Gateway
   ↓ Route to Public Subnet
3. Internet-facing ALB (Public Subnet)
   ↓ Forward to NLB IPs
4. Internal NLB (Private Subnet)
   ↓ Load Balance
5. Nginx Proxy Instances (2개, 로드밸런싱)
   ↓ Proxy Pass
6. Transit Gateway
   ↓ Route to Spoke
7. Spoke VPC Python Web Server
```

### 📤 아웃바운드 트래픽 (Spoke VPC)
```
1. Spoke EC2 Instance
   ↓ Route via TGW
2. Transit Gateway
   ↓ Route to Central
3. Central VPC Private Subnets
   ↓ Route via NAT
4. NAT Gateway
   ↓ Route to Internet
5. Internet Gateway
```

## 🎯 주요 특징

1. **✨ Count 미사용**: 모든 리소스를 개별적으로 정의하여 명확한 리소스 관리
2. **🆕 Amazon Linux 2023**: 최신 OS 사용
3. **🏢 Multi-AZ 고가용성**: 2개 가용 영역 활용
4. **🔄 Central-Spoke 아키텍처**: 중앙 집중식 네트워크 관리
5. **🔒 보안 프록시**: Nginx를 통한 트래픽 필터링 및 로드밸런싱
6. **🚫 완전한 격리**: Spoke VPC의 인터넷 직접 접근 차단
7. **🛠️ SSM 지원**: AWS Systems Manager를 통한 인스턴스 관리

## 🔍 모니터링 및 로그

### ✅ Health Check
- **ALB**: `/health` 경로 체크
- **NLB**: HTTP 8080 포트 `/health` 체크
- **Spoke EC2**: Python HTTP 서버 포트 80 체크

### 📋 로그 위치
- **Nginx 로그**: `/var/log/nginx/`
- **Python HTTP 서버 로그**: `/var/log/simple-http.log`

## 🔧 트러블슈팅

### ⚠️ 일반적인 문제들

1. **ALB Health Check 실패**
   - Proxy 인스턴스의 `/health` 엔드포인트 확인
   - Security Group 규칙 점검

2. **Spoke VPC 연결 문제**
   - Transit Gateway 라우팅 테이블 확인
   - Security Group 간 통신 규칙 점검

3. **DNS 해상도 문제**
   - VPC DNS 설정 확인 (enable_dns_hostnames, enable_dns_support)

### 💡 유용한 명령어

```bash
# Terraform 상태 확인
terraform show

# 특정 리소스 정보 확인
terraform state show aws_lb.internet_facing

# 리소스 의존성 그래프 생성
terraform graph | dot -Tsvg > graph.svg

# SSM을 통한 인스턴스 연결
aws ssm start-session --target <instance-id>

# 연결 테스트
curl http://<alb-dns-name>
```

## 🧪 테스트 방법

### 1. 전체 플로우 테스트
```bash
# ALB를 통한 엔드투엔드 테스트
curl http://central-spoke-internet-alb-1704316430.ap-northeast-2.elb.amazonaws.com

# 응답 예시:
# <html>
# <head><title>Spoke VPC Web Server</title></head>
# <body>
#     <h1>Spoke VPC Web Server</h1>
#     <p>Hostname: ip-10-1-10-107.ap-northeast-2.compute.internal</p>
#     <p>Instance ID: i-0091df477a905dba1</p>
#     <p>VPC: 10.1.0.0/16</p>
#     <p>Server: Python HTTP Server</p>
# </body>
# </html>
```

### 2. 연결성 테스트
```bash
# Proxy에서 Spoke로 연결 테스트 (SSM 사용)
aws ssm start-session --target <proxy-instance-id>
# 프록시에서:
telnet 10.1.10.107 80
telnet 10.1.10.107 22
```

## 📝 라이센스

이 프로젝트는 교육 및 데모 목적으로 제공됩니다.

## 🤝 기여 방법

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

---

**⚠️ 참고**: 이 구성은 프로덕션 환경에서 사용하기 전에 보안 검토 및 성능 테스트를 거쳐야 합니다.

**🎯 성공 확인**: 위의 테스트 명령어로 `Spoke VPC Web Server` 응답을 받으면 전체 아키텍처가 성공적으로 작동하는 것입니다!