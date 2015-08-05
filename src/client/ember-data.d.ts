interface FixtureAdapter {
    _fixtureAdapter: any; // Brand
    extend: (obj?) => FixtureAdapter;
}

interface EmberData {
    FixtureAdapter: FixtureAdapter;
}

declare var DS: EmberData;