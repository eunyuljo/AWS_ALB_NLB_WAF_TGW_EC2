# AWS Hub-Spoke Architecture with Load Balancers and Proxy

이 프로젝트는 AWS에서 Hub-Spoke 아키텍처를 구현하여 중앙 집중식 네트워크 관리와 보안 처리를 제공합니다.

## 🏗️ 아키텍처 개요

```
External Client
        ↓
Internet Gateway (Hub VPC)
        ↓
Internet-facing ALB (Public Subnet)
        ↓
Internal NLB (Private Subnet)
        ↓
Nginx Proxy Instances (Security Processing)
        ↓
Transit Gateway
        ↓
Spoke VPC Services (EC2 Web Servers)
```

## 📋 주요 구성 요소

### Hub VPC (중앙 허브)
- **CIDR**: 10.0.0.0/16
- **가용 영역**: ap-northeast-2a, ap-northeast-2c
- **Public Subnets**: 인터넷 게이트웨이 연결
- **Private Subnets**: NAT Gateway를 통한 아웃바운드 연결
- **구성 요소**:
  - Internet-facing Application Load Balancer
  - Internal Network Load Balancer
  - Nginx Proxy 인스턴스 (2개, 각 AZ에 1개씩)

### Spoke VPCs (마이크로서비스)
- **Spoke 1**: 10.1.0.0/16
- **Spoke 2**: 10.2.0.0/16
- **Spoke 3**: 10.3.0.0/16
- **특징**:
  - Internet Gateway 없음 (Hub를 통해서만 인터넷 접근)
  - 각 VPC마다 Internal ALB와 EC2 웹 서버 보유
  - Transit Gateway를 통해 Hub VPC와 연결

### Transit Gateway
- 모든 VPC 간 연결 관리
- Hub-Spoke 라우팅 구현
- Spoke VPC들은 Hub를 통해서만 인터넷 접근

## 🔧 기술 스택

- **Infrastructure**: Terraform
- **Cloud Provider**: AWS
- **Operating System**: Amazon Linux 2023
- **Web Server**: Apache HTTP Server (httpd)
- **Proxy**: Nginx
- **Load Balancers**: ALB (Application Load Balancer), NLB (Network Load Balancer)

## 📁 파일 구조

```
├── main.tf                 # Provider 설정 및 공통 데이터
├── variables.tf            # 변수 정의
├── hub-vpc.tf             # Hub VPC 및 네트워킹 리소스
├── transit-gateway.tf     # Transit Gateway 설정
├── spoke-vpcs.tf          # Spoke VPC들 정의
├── load-balancers.tf      # ALB/NLB 설정
├── proxy-instances.tf     # Nginx Proxy 인스턴스
├── spoke-instances.tf     # Spoke VPC 웹 서버들
├── outputs.tf             # 출력 값들
├── proxy-config.tftpl     # Nginx 설정 템플릿
└── terraform.tfvars.example # 변수 예제 파일
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
| `project_name` | hub-spoke | 프로젝트 이름 |
| `environment` | prod | 환경 이름 |
| `hub_vpc_cidr` | 10.0.0.0/16 | Hub VPC CIDR |
| `instance_type` | t3.medium | EC2 인스턴스 타입 |
| `key_name` | "" | EC2 키 페어 이름 |

## 📊 출력 값

배포 완료 후 다음 정보들이 출력됩니다:

- `alb_dns_name`: Internet-facing ALB DNS 이름
- `nlb_dns_name`: Internal NLB DNS 이름
- `spoke_lb_dns_names`: 각 Spoke VPC ALB DNS 이름들
- `hub_vpc_id`: Hub VPC ID
- `spoke_vpc_ids`: Spoke VPC ID들
- `transit_gateway_id`: Transit Gateway ID
- `proxy_instance_ids`: Proxy 인스턴스 ID들
- `spoke_web_instance_ids`: Spoke 웹 서버 인스턴스 ID들

## 🌐 네트워크 플로우

### 인바운드 트래픽
1. **External Client** → Internet Gateway
2. **Internet Gateway** → Internet-facing ALB (Public Subnet)
3. **ALB** → Internal NLB (Private Subnet)
4. **NLB** → Nginx Proxy Instances (2개, 로드밸런싱)
5. **Proxy** → Transit Gateway
6. **TGW** → Spoke VPC Internal ALBs
7. **Spoke ALBs** → EC2 Web Servers

### 아웃바운드 트래픽 (Spoke VPCs)
1. **Spoke EC2** → Transit Gateway
2. **TGW** → Hub VPC Private Subnets
3. **Hub Private** → NAT Gateway
4. **NAT Gateway** → Internet Gateway

## 🔒 보안 구성

### Security Groups
- **ALB Security Group**: HTTP(80) 인바운드 허용
- **Proxy Security Group**: Hub VPC에서 HTTP(8080), SSH(22) 허용
- **Spoke Security Groups**: Hub VPC에서 HTTP(80), SSH(22) 허용

### 네트워크 격리
- Spoke VPC들은 직접적인 인터넷 접근 불가
- 모든 트래픽은 Hub VPC를 경유
- Proxy 레이어에서 보안 정책 적용 가능

## 🎯 주요 특징

1. **Count 미사용**: 모든 리소스를 개별적으로 정의하여 명확한 리소스 관리
2. **Amazon Linux 2023**: 최신 OS 사용
3. **Multi-AZ 고가용성**: 2개 가용 영역 활용
4. **Hub-Spoke 아키텍처**: 중앙 집중식 네트워크 관리
5. **보안 프록시**: Nginx를 통한 트래픽 필터링 및 로드밸런싱
6. **완전한 격리**: Spoke VPC들의 인터넷 직접 접근 차단

## 🔍 모니터링 및 로그

### Health Check
- **ALB**: `/health` 경로 체크
- **NLB**: HTTP 8080 포트 체크
- **Spoke ALBs**: `/` 경로 체크

### 로그 위치
- **Nginx 로그**: `/var/log/nginx/`
- **Apache 로그**: `/var/log/httpd/`

## 🔧 트러블슈팅

### 일반적인 문제들

1. **ALB Health Check 실패**
   - Proxy 인스턴스의 `/health` 엔드포인트 확인
   - Security Group 규칙 점검

2. **Spoke VPC 연결 문제**
   - Transit Gateway 라우팅 테이블 확인
   - Security Group 간 통신 규칙 점검

3. **DNS 해상도 문제**
   - VPC DNS 설정 확인 (enable_dns_hostnames, enable_dns_support)

### 유용한 명령어

```bash
# Terraform 상태 확인
terraform show

# 특정 리소스 정보 확인
terraform state show aws_lb.internet_facing

# 리소스 의존성 그래프 생성
terraform graph | dot -Tsvg > graph.svg
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

**참고**: 이 구성은 프로덕션 환경에서 사용하기 전에 보안 검토 및 성능 테스트를 거쳐야 합니다.