## Swift Codable Implementation of SQLite [JSONB](https://sqlite.org/jsonb.html)

> [!CAUTION]
> This is a very quick extraction of code developed for a specific purpose in a larger project. It is only tested for that narrow use case and has a high potential for data loss. It also carries cruft from that larger project.


Credits
- I began by looking at [@zamazan4ik](https://github.com/zamazan4ik)'s Serde [implementation](https://github.com/zamazan4ik/serde-sqlite-jsonb)
- I benefited much from [conversation](https://github.com/groue/GRDB.swift/discussions/1656) with [@groue](https://github.com/groue)

This was developed for use with [GRDB](https://github.com/groue/GRDB.swift), which I highly recommend. GRDB is not a requirement, though, so I've commented-out the integration but left the file here: `JSONBConvertible`.

Also excluded, for similar reason, are proper tests that round-tripped encoded JSONB through an actual SQLite instance to ensure compatibility. Some of those tests are still here but commented-out.