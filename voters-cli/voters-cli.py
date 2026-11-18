#!/usr/bin/env python3
"""Command line client for the voters API, see README.md.

Uses only the Python standard library. The API's URL is --url or VOTERS_API_URL, default http://localhost:8080.
"""

import argparse
import json
import os
import shutil
import ssl
import sys
import urllib.error
import urllib.parse
import urllib.request

# The API's resources, /api/<resource>, with the columns the table output shows by default
RESOURCES = {
    "voters": ["id", "citizenName", "address", "postcode", "constituencyName", "openRegister", "registrationDate"],
    "citizens": ["id", "firstName", "surname", "gender", "statusCode", "birthDate", "died", "voterId"],
    "constituencies": ["id", "code", "name", "nation", "region", "ctype"],
    "postcodes": ["postcode", "conCode", "constituencyName"],
    "addresses": ["id", "address", "postcode", "placeName", "constituencyName"],
    "places": ["id", "name", "countryName"],
    "countries": ["id", "name"],
    "births": ["id", "citizenId", "citizenName", "date", "placeName", "fatherName", "motherName"],
    "marriages": ["id", "partner1Id", "partner1Name", "partner2Id", "partner2Name", "marriedDate", "divorcedDate"],
    "citizen-changes": ["id", "citizenId", "citizenName", "changeDate", "details"],
    "first-names": ["id", "name", "gender"],
    "surnames": ["id", "name"],
    "citizen-statuses": ["id", "code", "description"],
}

FILTERS = {
    "voters": "q (name), citizenId, addressId, postcode, placeId, constituencyId, openRegister",
    "citizens": "q (name), firstName, surname, gender, statusCode, alive",
    "constituencies": "q (name or code), nation, region",
    "postcodes": "q (postcode prefix), conCode",
    "addresses": "q (address), postcode, placeId, constituencyId",
    "places": "q (name), countryId",
    "countries": "q (name)",
    "births": "citizenId, fatherId, motherId, parentId, placeId",
    "marriages": "citizenId, current",
    "citizen-changes": "citizenId",
    "first-names": "q (name), gender",
    "surnames": "q (name)",
    "citizen-statuses": "",
}

# Fields set by id or by name, see cmd_update
NAMED_IDS = {"firstNameId": "firstName", "surnameId": "surname", "statusId": "statusCode"}


class ApiError(Exception):
    pass


class Client:
    def __init__(self, url, ca_cert=None, insecure=False):
        self.base = url.rstrip("/") + "/api/"
        self.context = None
        if insecure:
            self.context = ssl._create_unverified_context()
        elif ca_cert:
            self.context = ssl.create_default_context(cafile=ca_cert)

    def request(self, method, path, params=None, body=None):
        url = self.base + path
        if params:
            url += "?" + urllib.parse.urlencode({k: v for k, v in params.items() if v is not None})
        data = json.dumps(body).encode() if body is not None else None
        req = urllib.request.Request(url, data=data, method=method, headers={"Accept": "application/json"})
        if data is not None:
            req.add_header("Content-Type", "application/json")
        try:
            with urllib.request.urlopen(req, context=self.context) as res:
                content = res.read()
                return json.loads(content) if content else None
        except urllib.error.HTTPError as e:
            try:
                problem = json.loads(e.read())
                detail = problem.get("detail") or problem.get("error") or problem
            except ValueError:
                detail = e.reason
            raise ApiError(f"{e.code} {e.reason}: {detail}") from None
        except urllib.error.URLError as e:
            raise ApiError(f"Can't reach the API at {self.base}: {e.reason}") from None


def parse_assignments(items):
    """key=value sets a string, the API converts it to a number, boolean or date as needed. key:=json sets a JSON
    value, e.g. details:='{"type": "surname_change"}' or died:=null."""
    values = {}
    for item in items or []:
        key, sep, value = item.partition("=")
        if not sep or not key:
            raise ApiError(f"Expected key=value or key:=json, not {item}")
        if key.endswith(":"):
            try:
                values[key[:-1]] = json.loads(value)
            except ValueError:
                raise ApiError(f"{key}= must be followed by JSON, not {value}") from None
        else:
            values[key] = value
    return values


def read_body(args):
    body = {}
    if args.file:
        source = sys.stdin if args.file == "-" else open(args.file, encoding="utf-8")
        with source:
            body = json.load(source)
    body.update(parse_assignments(args.set))
    return body


def format_value(value):
    if value is None:
        return ""
    if isinstance(value, bool):
        return "yes" if value else "no"
    if isinstance(value, (dict, list)):
        return json.dumps(value, separators=(",", ":"))
    return str(value)


def print_table(rows, columns):
    if not rows:
        print("No records found.")
        return
    columns = columns or list(rows[0].keys())
    cells = [[format_value(row.get(c)) for c in columns] for row in rows]
    widths = [max(len(c), *(len(r[i]) for r in cells)) for i, c in enumerate(columns)]
    # Shrink the widest columns until the table fits the terminal
    available = shutil.get_terminal_size((160, 24)).columns - 2 * (len(columns) - 1)
    while sum(widths) > available and max(widths) > 12:
        widths[widths.index(max(widths))] -= 1
    clip = lambda text, w: text if len(text) <= w else text[: max(w - 1, 0)] + "…"
    print("  ".join(clip(c, w).ljust(w) for c, w in zip(columns, widths)).rstrip())
    print("  ".join("-" * w for w in widths))
    for r in cells:
        print("  ".join(clip(v, w).ljust(w) for v, w in zip(r, widths)).rstrip())


def print_record(record):
    width = max(len(k) for k in record)
    for key, value in record.items():
        print(f"{key.ljust(width)}  {format_value(value)}")


def output(args, data, columns=None):
    if args.output == "json":
        json.dump(data, sys.stdout, indent=2)
        print()
    elif isinstance(data, list):
        print_table(data, columns)
    elif data is not None:
        print_record(data)


def resource_arg(value):
    if value not in RESOURCES:
        raise argparse.ArgumentTypeError(f"unknown resource {value}, one of: {', '.join(RESOURCES)}")
    return value


def cmd_resources(client, args):
    rows = [{"resource": name, "filters": FILTERS[name]} for name in RESOURCES]
    output(args, rows, ["resource", "filters"])


def cmd_stats(client, args):
    stats = client.request("GET", "statistics")
    if args.output == "json":
        output(args, stats)
        return
    rows = [{"table": k, "rows": v} for k, v in stats["counts"].items()]
    rows += [{"table": k, "rows": stats[k]} for k in ("votersOnOpenRegister", "citizensAlive", "citizensMale", "citizensFemale")]
    print_table(rows, ["table", "rows"])


def cmd_list(client, args):
    params = parse_assignments(args.filter)
    params.update({"page": args.page, "size": args.size, "sort": args.sort})
    rows = []
    while True:
        page = client.request("GET", args.resource, params)
        rows += page["content"]
        info = page["page"]
        if not args.all or info["number"] + 1 >= info["totalPages"]:
            break
        params["page"] = info["number"] + 1
    columns = args.columns.split(",") if args.columns else RESOURCES[args.resource]
    output(args, rows, columns)
    if args.output == "table" and not args.all:
        print(f"\nPage {info['number'] + 1} of {max(info['totalPages'], 1)}, {info['totalElements']} records", file=sys.stderr)


def cmd_get(client, args):
    output(args, client.request("GET", f"{args.resource}/{urllib.parse.quote(args.id)}"))


def cmd_create(client, args):
    output(args, client.request("POST", args.resource, body=read_body(args)))


def cmd_update(client, args):
    path = f"{args.resource}/{urllib.parse.quote(args.id)}"
    record = client.request("GET", path)
    changes = read_body(args)
    # The API uses a name or status code in preference to its id, see CitizenDto, so a changed id clears the
    # record's current name or code
    for id_key, name_key in NAMED_IDS.items():
        if id_key in changes and name_key in record and name_key not in changes:
            changes[name_key] = None
    record.update(changes)
    output(args, client.request("PUT", path, body=record))


def cmd_delete(client, args):
    client.request("DELETE", f"{args.resource}/{urllib.parse.quote(args.id)}")
    print(f"Deleted {args.resource} {args.id}", file=sys.stderr)


def build_parser():
    parser = argparse.ArgumentParser(
        prog="voters-cli",
        description="Query and update the voter register using the voters API.",
        epilog="Examples:\n"
               "  voters-cli list constituencies -f q=bristol\n"
               "  voters-cli list voters -f constituencyId=12 --sort registrationDate,desc\n"
               "  voters-cli get citizens 42\n"
               "  voters-cli create citizens --set firstName=Ada --set surname=Lovelace --set gender=F --set statusCode=B\n"
               "  voters-cli update voters 7 --set openRegister=true\n"
               "  voters-cli delete marriages 3",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--url", default=os.environ.get("VOTERS_API_URL", "http://localhost:8080"),
                        help="the API's URL, default VOTERS_API_URL or http://localhost:8080")
    parser.add_argument("--ca-cert", default=os.environ.get("VOTERS_API_CA_CERT"),
                        help="CA certificate for an https URL, e.g. the cluster repository's resources/CA.cer, default VOTERS_API_CA_CERT")
    parser.add_argument("--insecure", action="store_true", help="don't verify the https certificate")
    parser.add_argument("-o", "--output", choices=["table", "json"], default="table", help="output format, default table")
    sub = parser.add_subparsers(dest="command", required=True, metavar="command")

    sub.add_parser("resources", help="list the resources and their filters").set_defaults(func=cmd_resources)
    sub.add_parser("stats", help="show the number of records").set_defaults(func=cmd_stats)

    p = sub.add_parser("list", help="list a resource's records")
    p.add_argument("resource", type=resource_arg)
    p.add_argument("-f", "--filter", action="append", metavar="KEY=VALUE", help="filter, repeatable, see the resources command")
    p.add_argument("--page", type=int, default=0, help="page number, from 0")
    p.add_argument("--size", type=int, default=20, help="page size, default 20, maximum 500")
    p.add_argument("--sort", help="sort property and direction, e.g. name or registrationDate,desc")
    p.add_argument("--all", action="store_true", help="fetch every page")
    p.add_argument("--columns", help="comma separated columns for the table output")
    p.set_defaults(func=cmd_list)

    p = sub.add_parser("get", help="show a record")
    p.add_argument("resource", type=resource_arg)
    p.add_argument("id")
    p.set_defaults(func=cmd_get)

    for name, func, help_text in (("create", cmd_create, "create a record"),
                                  ("update", cmd_update, "change a record's fields, the others are kept")):
        p = sub.add_parser(name, help=help_text)
        p.add_argument("resource", type=resource_arg)
        if name == "update":
            p.add_argument("id")
        p.add_argument("--set", action="append", metavar="KEY=VALUE",
                       help="set a field, repeatable, KEY:=JSON sets a JSON value, e.g. died:=null")
        p.add_argument("--file", help="JSON file with the fields, - for stdin, --set values override it")
        p.set_defaults(func=func)

    p = sub.add_parser("delete", help="delete a record")
    p.add_argument("resource", type=resource_arg)
    p.add_argument("id")
    p.set_defaults(func=cmd_delete)
    return parser


def main(argv=None):
    args = build_parser().parse_args(argv)
    client = Client(args.url, args.ca_cert, args.insecure)
    try:
        args.func(client, args)
    except ApiError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1
    except (OSError, ValueError) as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
