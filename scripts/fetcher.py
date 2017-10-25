import sys
import argparse
from Bio import Entrez
import xml.etree.ElementTree as ET

Entrez.email = "Afsrtfgdsfg@bobxx.com"


# def search
#     request = Entrez.epost("sra",id=",".join(id_list))
#     try:
#         result = Entrez.read(request)
#     except RuntimeError as e:
#         #FIXME: How generate NAs instead of causing an error with invalid IDs?
#         print ("An error occurred while retrieving the annotations.")
#         print ("The error returned was %s" % e)
#         sys.exit(-1)

#     webEnv = result["WebEnv"]
#     queryKey = result["QueryKey"]
#     data = Entrez.esummary(db="sra", webenv=webEnv, query_key =
#             queryKey)

def elink(idkey, db, source_db):
    res=None
    handle = Entrez.elink(db=db, dbfrom=source_db, id=idkey)
    for each in Entrez.read(handle):
        try:
            # print(each)
            res = each['LinkSetDb'][0]['Link'][0]['Id']
            # print(res)
        except IndexError:
            pass
    if res is not None:
        return(res)
    return (None)


def retrieve_annotation(id_list):

    """Annotates Entrez Gene IDs using Bio.Entrez, in particular epost (to
    submit the data to NCBI) and esummary to retrieve the information.
    Returns a list of dictionaries with the annotations."""

    request = Entrez.epost("sra",id=",".join(id_list))
    try:
        result = Entrez.read(request)
    except RuntimeError as e:
        #FIXME: How generate NAs instead of causing an error with invalid IDs?
        sys.stderr.write("An error occurred while retrieving the annotations.\n")
        sys.stderr.write("The error returned was %s\n" % e)
        sys.exit(-1)

    webEnv = result["WebEnv"]
    queryKey = result["QueryKey"]
    data = Entrez.esummary(db="sra", webenv=webEnv, query_key =
            queryKey)
    annotations = Entrez.read(data)
    # print(annotations)
    sys.stderr.write("Retrieved %d annotations for %d accession\n" % (len(annotations),
            len(id_list)))
    subxml = parseExpXml(xmlData="<tag>" + annotations[0]["ExpXml"] + "</tag>")

    return (annotations[0], subxml)

def parseExpXml(xmlData):
    xml = ET.fromstring(xmlData)
    resdict = {}
    for child in xml:
        if child.text:
            resdict[child.tag] = child.text
        else:
            for subchild in child:
                if subchild.text:
                    resdict[child.tag + "." + subchild.tag] = subchild.text
                else:
                    resdict[child.tag + "." + subchild.tag] = subchild
    return resdict


def get_args():
    parser = argparse.ArgumentParser(
        description="gets the SRA for a nucleotide accession")
    parser.add_argument(
        'input', metavar="input", help="nuccore accession")
    parser.add_argument(
        '-s',"--source_db",
        # choices=["assembly", "bioproject", 'biosample', "nuccore"],
        choices=["nuccore"],
        default="nuccore",
        metavar="db", help="db to search")
    return( parser.parse_args())


def main(args=None):
    if args is None:
        args = get_args()
    biosample_uid = elink(idkey=args.input,
                          source_db=args.source_db,
                          db="biosample")
    res = None
    if biosample_uid is not None:
        sys.stderr.write(
            "linking the following biosample to sra: " + biosample_uid + "\n")
        sra_uid = elink(idkey=biosample_uid,
                        source_db="biosample",
                        db="sra")
        if sra_uid is not None:
            sys.stderr.write("fetching summary for sra " + sra_uid + "\n")
            res, res_details = retrieve_annotation([sra_uid])
    if res is None:
        line = "{0}\t\t\t\t\t\t".format(args.input)
    else:
        # print(res["Runs"].split())
        # splits xml node (ignoring the first tag, as it is just "run"
        run_details = dict(s.split('=', 1) for s in res["Runs"].split()[1:])
        line = "{0}\t{1}\t{2}\t{3}\t{4}\t{5}\t{6}".format( #\t{7}\t{8}\t{9}\t{10}".format(
            args.input, #0
            res["Id"], #1
            res_details["Summary.Title"], #2
            run_details["acc"], #3
            res["CreateDate"], #4
            res["UpdateDate"], #5
            res_details["Bioproject"] #6
            )
        #7
            #8
            #9
            #10
    sys.stdout.write(line + "\n")

if __name__ == "__main__":
    args = get_args()
    main(args)
