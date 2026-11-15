FROM rust:1.85-bookworm

ARG KANI_VERSION=0.68.0
ARG RUST_NIGHTLY=nightly-2026-08-21
LABEL org.opencontainers.image.title="SabkaProof Kani worker"
LABEL org.opencontainers.image.description="Pinned, isolated Rust/Kani verification runtime"
LABEL sabkaproof.rust-nightly="${RUST_NIGHTLY}"
LABEL sabkaproof.kani-version="${KANI_VERSION}"
LABEL sabkaproof.evidence-format="cbmc-xml-trace"

RUN rustup toolchain install "${RUST_NIGHTLY}" --profile minimal --no-self-update \
    && rustup default "${RUST_NIGHTLY}" \
    && cargo install --locked kani-verifier --version "${KANI_VERSION}"

RUN useradd --uid 1000 --create-home --shell /usr/sbin/nologin kani

USER kani
WORKDIR /workspace
RUN cargo kani setup

# Entrypoint changes must not invalidate the downloaded verifier bundle.
USER root
COPY entrypoint.sh /usr/local/bin/sabkaproof-kani-worker
RUN chmod 0555 /usr/local/bin/sabkaproof-kani-worker
USER kani

ENV HOME=/home/kani \
    CARGO_HOME=/tmp/cargo \
    CARGO_TARGET_DIR=/workspace/.cargo-target \
    CARGO_NET_OFFLINE=true \
    CARGO_TERM_COLOR=never \
    RUST_BACKTRACE=1

ENTRYPOINT ["/usr/local/bin/sabkaproof-kani-worker"]