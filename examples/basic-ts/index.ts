import * as pulumi from "@pulumi/pulumi";
import * as xyz from "@pulumi/xyz";

const resource = new xyz.Resource("Resource", { sampleAttribute: "attr" });

export const sampleAttribute = resource.sampleAttribute;
