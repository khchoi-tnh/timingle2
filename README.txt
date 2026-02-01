#########################################################
# 모든 마이그레이션 순서대로 실행
#########################################################
cd /mnt/d/projects/timingle2/backend

for f in migrations/001*.sql migrations/002*.sql migrations/003*.sql migrations/004*.sql migrations/005*.sql migrations/006*.sql migrations/007*.sql; do
  echo "Running $f..."
  podman exec -i timingle-postgres psql -U timingle -d timingle < $f
done

# Podman으로 마이그레이션 실행
podman exec -i timingle-postgres psql -U timingle -d timingle -f - < backend/migrations/009_create_friendships_table.sql
podman exec -i timingle-postgres psql -U timingle -d timingle -f - < backend/migrations/010_alter_event_participants.sql
podman exec -i timingle-postgres psql -U timingle -d timingle -f - < backend/migrations/011_create_event_invite_links.sql


#########################################################
for f in migrations/*.sql; do echo "=== $f ==="; podman exec -i timingle-postgres psql -U timingle -d timingle < $f; done

cat /mnt/d/projects/timingle2/backend/migrations/00{9,10,11}*.sql | podman exec -i timingle-postgres psql -U timingle -d timingle

#########################################################
# build && run
#########################################################
./build.sh&& ./run.sh  


완료. ScyllaDB 5.4 → 2025.4로 업데이트했습니다.

#########################################################
# 실행순서
#########################################################
# WSL에서
cd ~/projects/timingle2/containers
podman rm -f timingle-scylla
podman volume rm containers_scylla_data
./setup_podman.sh

# WSL에서
cd ~/projects/timingle2/containers
podman rm -af
podman volume rm -a   # 데이터 초기화 (주의!)

# 1. 컨테이너 시작
cd ~/projects/timingle2/containers
./setup_podman.sh

# 2. Backend 실행
cd ~/projects/timingle2/backend
./run.sh

# 3. 확인
curl http://localhost:8080/api/v1/health
# → {"status":"ok"}
