# Flutter Clean Architecture 레이어 흐름

Flutter 앱의 Clean Architecture 구조와 Google OAuth 로그인 시 각 레이어의 역할입니다.

## 레이어 구조

```mermaid
flowchart TB
    subgraph Presentation["🎨 Presentation Layer"]
        UI[LoginPage]
        Provider[AuthProvider/Notifier]
    end

    subgraph Domain["🧠 Domain Layer"]
        UseCase[LoginWithGoogle UseCase]
        Entity[User Entity]
        RepoInterface[AuthRepository Interface]
    end

    subgraph Data["💾 Data Layer"]
        RepoImpl[AuthRepositoryImpl]
        DataSource[AuthRemoteDataSource]
        Model[UserModel]
    end

    subgraph External["🌐 External"]
        GoogleSignIn[GoogleSignIn Package]
        API[Backend API]
    end

    UI --> Provider
    Provider --> UseCase
    UseCase --> RepoInterface
    RepoInterface -.-> RepoImpl
    RepoImpl --> DataSource
    RepoImpl --> GoogleSignIn
    DataSource --> API
    Model --> Entity
```

## Google 로그인 시퀀스

```mermaid
sequenceDiagram
    autonumber
    participant UI as 🎨 LoginPage
    participant P as 📦 AuthNotifier
    participant UC as 🧠 LoginWithGoogle
    participant R as 💾 AuthRepositoryImpl
    participant GS as 🔵 GoogleSignIn
    participant DS as 📡 RemoteDataSource
    participant API as 🖥️ Backend

    Note over UI,API: Flutter Clean Architecture 흐름

    UI->>P: loginWithGoogle() 호출
    P->>P: state = loading

    P->>UC: call(NoParams())
    UC->>R: loginWithGoogle()

    rect rgb(240, 248, 255)
        Note over R,GS: Google Sign-In
        R->>GS: signIn()
        GS-->>GS: 로그인 화면 표시
        GS->>R: GoogleSignInAccount
        R->>GS: authentication
        GS->>R: idToken
    end

    rect rgb(255, 248, 240)
        Note over R,API: Backend API 호출
        R->>DS: loginWithGoogle(idToken, platform)
        DS->>API: POST /auth/google
        API->>DS: { access_token, user }
        DS->>R: (UserModel, tokens)
    end

    R->>R: _saveAuthState()
    Note right of R: TokenStorage 저장<br/>ApiClient 토큰 설정

    R->>UC: Right((User, AuthTokens))
    UC->>P: Either<Failure, (User, AuthTokens)>

    alt 성공
        P->>P: state = authenticated
        P->>UI: user 정보 반영
    else 실패
        P->>P: state = error
        P->>UI: 에러 메시지 표시
    end
```

## 파일 구조

```mermaid
flowchart LR
    subgraph features/auth
        subgraph presentation
            P1[pages/login_page.dart]
            P2[providers/auth_provider.dart]
        end

        subgraph domain
            D1[entities/user.dart]
            D2[entities/auth_tokens.dart]
            D3[repositories/auth_repository.dart]
            D4[usecases/login_with_google.dart]
        end

        subgraph data
            DA1[models/user_model.dart]
            DA2[datasources/auth_remote_datasource.dart]
            DA3[repositories/auth_repository_impl.dart]
        end
    end

    P1 --> P2
    P2 --> D4
    D4 --> D3
    D3 -.->|implements| DA3
    DA3 --> DA2
    DA3 --> DA1
    DA1 -->|extends| D1
```

## 의존성 방향

```mermaid
flowchart BT
    subgraph External["External (Framework/Library)"]
        E1[Flutter]
        E2[Dio]
        E3[GoogleSignIn]
        E4[Riverpod]
    end

    subgraph Data["Data Layer"]
        D1[Repository Impl]
        D2[DataSource]
        D3[Models]
    end

    subgraph Domain["Domain Layer (Core)"]
        DO1[Entities]
        DO2[Repository Interface]
        DO3[UseCases]
    end

    subgraph Presentation["Presentation Layer"]
        P1[Pages]
        P2[Providers]
        P3[Widgets]
    end

    Data --> Domain
    Presentation --> Domain
    External --> Data
    External --> Presentation

    style Domain fill:#e1f5fe
    style Data fill:#fff3e0
    style Presentation fill:#f3e5f5
    style External fill:#e8f5e9
```

## Provider 의존성

```mermaid
flowchart TD
    subgraph Providers
        API[apiClientProvider]
        TS[tokenStorageProvider]
        WS[webSocketClientProvider]

        RDS[authRemoteDataSourceProvider]
        REPO[authRepositoryProvider]

        UC1[registerWithPhoneUseCaseProvider]
        UC2[loginWithGoogleUseCaseProvider]
        UC3[logoutUseCaseProvider]

        AUTH[authProvider]
    end

    API --> RDS
    RDS --> REPO
    TS --> REPO
    API --> REPO
    WS --> REPO

    REPO --> UC1
    REPO --> UC2
    REPO --> UC3

    UC1 --> AUTH
    UC2 --> AUTH
    UC3 --> AUTH
```

## 에러 처리 흐름

```mermaid
sequenceDiagram
    participant R as Repository
    participant E as Either<Failure, T>
    participant P as Provider
    participant UI as UI

    R->>R: try-catch 블록

    alt ServerException
        R->>E: Left(ServerFailure)
    else NetworkException
        R->>E: Left(NetworkFailure)
    else AuthException
        R->>E: Left(AuthFailure)
    else Unknown
        R->>E: Left(UnknownFailure)
    end

    E->>P: fold(onFailure, onSuccess)

    alt Failure
        P->>P: state = error
        P->>UI: errorMessage 표시
    else Success
        P->>P: state = authenticated
        P->>UI: user 정보 반영
    end
```

## 관련 파일

| 레이어 | 파일 |
|-------|------|
| Presentation | `lib/features/auth/presentation/providers/auth_provider.dart` |
| Domain | `lib/features/auth/domain/usecases/login_with_google.dart` |
| Domain | `lib/features/auth/domain/repositories/auth_repository.dart` |
| Data | `lib/features/auth/data/repositories/auth_repository_impl.dart` |
| Data | `lib/features/auth/data/datasources/auth_remote_datasource.dart` |
