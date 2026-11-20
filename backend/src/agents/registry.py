from agents.spec import AgentSpec

_SPECS: dict[str, AgentSpec] = {}


def register(spec: AgentSpec) -> AgentSpec:
    existing = _SPECS.get(spec.name)
    if existing is not None and existing != spec:
        raise ValueError(f"Agent spec already registered with a different definition: {spec.name}")
    _SPECS[spec.name] = spec
    return spec


def get_spec(name: str) -> AgentSpec:
    try:
        return _SPECS[name]
    except KeyError:
        raise KeyError(f"Agent spec is not registered: {name}") from None


def all_specs() -> tuple[AgentSpec, ...]:
    return tuple(_SPECS.values())
