# Backend-Driven Authentication and Removal of Client-Side Demo Accounts

The client previously embedded hardcoded quick demo credentials (`chef@bokrah.com`, `0501234567`) directly on the sign-in screen for local prototyping. We decided to completely eliminate client-side demo accounts from both release and debug UI, standardizing authentication strictly against real backend endpoints (`POST /api/auth/login`). Unauthenticated exploration is fulfilled natively by Guest Mode, while staging and testing verification is handled by authentic test accounts managed by the backend.

