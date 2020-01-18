# Diff

Website to display diffs between Hex package versions.

## Contributing

### Setup

1. Run `mix setup` to install dependencies etc
2. Run `mix test`
3. Run `mix phx.server` and visit [http://localhost:4004/](http://localhost:4004/)

### Node Dependencies

For assets compilation we need to install Node dependencies:

```shell
cd assets && yarn install
```

If you don't have yarn installed, `cd assets && npm install` will work too.

## License

    Copyright 2020 Johanna Larsson
    Copyright 2020 Six Colors AB

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
