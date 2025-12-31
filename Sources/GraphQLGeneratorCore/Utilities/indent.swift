extension String {
    func indent(_ num: Int, includeFirst: Bool = true) -> String {
        let indent = String(repeating: "    ", count: num)
        return prefixLines(with: indent, includeFirst: includeFirst)
    }

    func docComment() -> String {
        return prefixLines(with: "/// ", includeFirst: true)
    }

    private func prefixLines(with prefix: any StringProtocol, includeFirst: Bool) -> String {
        var firstLine = true
        return split(separator: "\n").map { line in
            var result = line
            if !line.isEmpty {
                if !firstLine || includeFirst {
                    result = prefix + line
                }
            }
            firstLine = false
            return result
        }.joined(separator: "\n")
    }
}
